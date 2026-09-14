import Foundation
import SwiftData
import UserNotifications

/// 通知の許可と予約を担う。何を予約するかの判断は `NotificationPlanner` 側にある。
///
/// 予約は常に「全削除 → 計画を作り直して全登録」。差分を追うより単純で壊れない。
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
            reminderDays: defaults.string(forKey: StorageKey.reminderDays)
                .map(NotificationSettings.decode) ?? NotificationSettings.defaultReminderDays,
            hour: defaults.object(forKey: StorageKey.notifyHour) as? Int ?? 9,
            minute: defaults.object(forKey: StorageKey.notifyMinute) as? Int ?? 0,
            trialAlerts: defaults.object(forKey: StorageKey.trialAlerts) as? Bool ?? true,
            yearlyWeekBefore: defaults.object(forKey: StorageKey.yearlyWeekBefore) as? Bool ?? true
        )
    }

    /// 予約をすべて入れ替える。
    ///
    /// - Parameter requestingAuthorization: 未確認のときに許可ダイアログを出すか。
    ///   自動の組み直しでは false にして、許可はオンボーディングと設定画面でだけ求める。
    /// - Returns: 予約した件数。通知が許可されていなければ nil。
    @discardableResult
    func replaceAll(with planned: [PlannedNotification], requestingAuthorization: Bool = false) async -> Int? {
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

/// 保存済みのサブスクから通知を組み直し、次のバックグラウンド組み直しを予約する入口。
///
/// 呼ぶ場所: 起動・復帰時（`SubsNoteApp`）／BGAppRefreshTask／保存・削除・解約・再開の直後／通知設定の変更後／設定の「通知を作り直す」。
@MainActor
enum NotificationRefresh {
    @discardableResult
    static func run(
        container: ModelContainer, now: Date = Date(), requestingAuthorization: Bool = false
    ) async -> Int? {
        // await の前に値へ写しておく（モデルを中断点をまたいで持ち回らない）。
        let inputs = ((try? container.mainContext.fetch(FetchDescriptor<Subscription>())) ?? [])
            .map(\.notificationInput)
        let planned = NotificationPlanner.plan(
            subscriptions: inputs, settings: NotificationScheduler.currentSettings(), now: now
        )
        let scheduled = await NotificationScheduler.shared.replaceAll(
            with: planned, requestingAuthorization: requestingAuthorization
        )
        if scheduled != nil, let date = BackgroundRefreshPolicy.nextRefreshDate(planned: planned, now: now) {
            BackgroundRefresh.schedule(at: date)
        } else {
            // 未許可・通知が不要になった場合は、残っている予約を片付ける（許可後は復帰時に組み直す）。
            BackgroundRefresh.cancel()
        }
        return scheduled
    }
}
