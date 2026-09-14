import Foundation
import SwiftData
import UserNotifications

/// メンテ通知の許可と予約を担う。何を予約するかの判断は `NotificationPlanner` 側にある。
///
/// 予約は常に「全削除 → 計画を作り直して全登録」。予約は1項目1件・多くても十数件なので、
/// 差分を追うより毎回作り直すほうが単純で壊れない（GomiAlarm と同じ方式・BGTask は持たない）。
@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// 明示的に拒否されているか（設定画面で「通知が届きません」を出すため）。
    func isDenied() async -> Bool {
        await authorizationStatus() == .denied
    }

    func isAuthorized() async -> Bool {
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    /// 未確認なら許可をリクエストし、利用可能かを返す。
    func requestAuthorizationIfNeeded() async -> Bool {
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    /// 予約を作り直す。アプリ起動時・給油やメンテの記録後・設定変更後に呼ぶ。
    ///
    /// - Parameter requestingAuthorization: 未確認のときに許可ダイアログを出すか。
    ///   自動の組み直しでは false にして、許可はオンボーディングと設定画面でだけ求める。
    /// - Returns: 予約した件数。通知が許可されていなければ nil。
    @discardableResult
    func rebuild(
        context: ModelContext, now: Date = Date(), requestingAuthorization: Bool = false
    ) async -> Int? {
        // await の前に値へ写しておく（モデルを中断点をまたいで持ち回らない）。
        let vehicles = ((try? context.fetch(FetchDescriptor<Vehicle>(sortBy: [SortDescriptor(\.sortOrder)]))) ?? [])
            .map(\.notificationInput)
        let planned = NotificationPlanner.plan(vehicles: vehicles, now: now)

        center.removeAllPendingNotificationRequests()
        let authorized = requestingAuthorization
            ? await requestAuthorizationIfNeeded()
            : await isAuthorized()
        guard authorized else { return nil }

        var scheduled = 0
        for notification in planned {
            do {
                try await center.add(request(for: notification))
                scheduled += 1
            } catch {
                continue
            }
        }
        return scheduled
    }

    func pendingCount() async -> Int {
        await center.pendingNotificationRequests().count
    }

    private func request(for planned: PlannedMaintenanceNotification) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = planned.title
        content.body = planned.body
        content.sound = .default
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: planned.fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: planned.id, content: content, trigger: trigger)
    }
}
