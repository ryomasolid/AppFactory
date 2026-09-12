import Foundation
import UserNotifications

/// ローカル通知の許可と登録を担う。何を登録するかの判断は `NotificationPlanner` 側にある。
///
/// 登録は常に「全削除 → 計画を作り直して全登録」。差分更新はバグの温床になるうえ、
/// 保留通知は最大64件しか持てず状態が勝手に減るので、毎回作り直す方が安全。
@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // 通知アクション用の識別子。
    static let categoryID = "GOMI_REMINDER"
    static let doneActionID = "DONE"
    static let snoozeActionID = "SNOOZE"

    /// 再構築の結果。設定画面やデバッグ表示に使う。
    struct RebuildResult: Equatable, Sendable {
        var authorized: Bool
        var scheduled: Int
        var failed: Int
        var isPermanent: Bool
        var coveredThrough: Date?
        var truncated: Bool

        static let unauthorized = RebuildResult(
            authorized: false, scheduled: 0, failed: 0,
            isPermanent: false, coveredThrough: nil, truncated: false
        )
    }

    /// 通知に「出した」「1時間後に再通知」を付けるカテゴリを登録する。起動時に1回呼ぶ。
    func registerCategories() {
        let done = UNNotificationAction(
            identifier: Self.doneActionID, title: String(localized: "出した"), options: []
        )
        let snooze = UNNotificationAction(
            identifier: Self.snoozeActionID, title: String(localized: "1時間後に再通知"), options: []
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryID, actions: [done, snooze], intentIdentifiers: []
        )
        center.setNotificationCategories([category])
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// 明示的に拒否されているか（ホーム／設定で「通知が届きません」バナーを出すため）。
    func isDenied() async -> Bool {
        await authorizationStatus() == .denied
    }

    /// すでに許可済みか（ダイアログは出さない）。
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

    /// 保留中の通知を作り直す。アプリ起動時・種類や設定の変更後に呼ぶ。
    /// - Parameter requestingAuthorization: 未確認のときに許可ダイアログを出すか。
    ///   起動時やバックグラウンドの自動実行では false にして、許可はオンボーディングでだけ求める。
    @discardableResult
    func rebuild(
        kinds: [KindPlan],
        settings: NotificationSettings = .load(),
        now: Date = Date(),
        requestingAuthorization: Bool = false
    ) async -> RebuildResult {
        center.removeAllPendingNotificationRequests()
        let authorized = requestingAuthorization
            ? await requestAuthorizationIfNeeded()
            : await isAuthorized()
        guard authorized else { return .unauthorized }

        let plan = NotificationPlanner.plan(kinds: kinds, settings: settings, now: now)
        var scheduled = 0
        var failed = 0
        for planned in plan.notifications {
            do {
                try await center.add(request(for: planned))
                scheduled += 1
            } catch {
                failed += 1
            }
        }
        return RebuildResult(
            authorized: true,
            scheduled: scheduled,
            failed: failed,
            isPermanent: plan.isPermanent,
            coveredThrough: plan.coveredThrough,
            truncated: plan.truncated
        )
    }

    /// 通知アクション「1時間後に再通知」用。
    func snooze(title: String, body: String, after interval: TimeInterval = 3600) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        try? await center.add(
            UNNotificationRequest(identifier: "snooze-\(UUID().uuidString)", content: content, trigger: trigger)
        )
    }

    /// 現在の保留件数（64件上限にどれだけ近いかの確認用）。
    func pendingCount() async -> Int {
        await center.pendingNotificationRequests().count
    }

    // MARK: - 変換

    private func request(for planned: PlannedNotification) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = planned.title
        content.body = planned.body
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        content.userInfo = [
            "kindIDs": planned.kindIDs.map(\.uuidString),
            "timing": planned.timing.rawValue,
            "collectionDate": planned.collectionDate?.timeIntervalSince1970 ?? 0,
        ]

        let trigger: UNNotificationTrigger
        switch planned.trigger {
        case let .weeklyRepeating(fireWeekday, time):
            let components = DateComponents(
                hour: time.hour, minute: time.minute, weekday: fireWeekday.rawValue
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        case let .oneShot(fireDate):
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute], from: fireDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        return UNNotificationRequest(identifier: planned.id, content: content, trigger: trigger)
    }
}
