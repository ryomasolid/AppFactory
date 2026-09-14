import Foundation
import SwiftData
import UserNotifications

/// 保証期限の通知の許可と予約を担う。何を予約するかの判断は `NotificationPlanner` 側にある。
///
/// 予約は常に「全削除 → 計画を作り直して全登録」。差分を追うより単純で壊れない（CarLog と同じ方式・BGTask は持たない）。
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

    /// 設定画面の値（`@AppStorage`）を読む。
    static func currentSettings(defaults: UserDefaults = .standard) -> NotificationSettings {
        NotificationSettings(
            timing: defaults.string(forKey: StorageKey.notificationTiming)
                .flatMap(NotificationTiming.init(rawValue:)) ?? .thirtyAndSeven,
            hour: defaults.object(forKey: StorageKey.notifyHour) as? Int ?? 9,
            minute: defaults.object(forKey: StorageKey.notifyMinute) as? Int ?? 0
        )
    }

    /// 予約を作り直す。起動・復帰時、商品の保存・削除・アーカイブ後、通知設定の変更後に呼ぶ。
    ///
    /// - Parameter requestingAuthorization: 未確認のときに許可ダイアログを出すか。
    ///   自動の組み直しでは false にして、許可はオンボーディングと設定画面でだけ求める。
    /// - Returns: 予約した件数。通知が許可されていなければ nil。
    @discardableResult
    func rebuild(
        context: ModelContext, now: Date = Date(), requestingAuthorization: Bool = false
    ) async -> Int? {
        // await の前に値へ写しておく（モデルを中断点をまたいで持ち回らない）。
        let items = ((try? context.fetch(FetchDescriptor<Item>())) ?? []).map(\.notificationInput)
        let planned = NotificationPlanner.plan(items: items, settings: Self.currentSettings(), now: now)

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

    private func request(for planned: PlannedNotification) -> UNNotificationRequest {
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
