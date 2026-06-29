import Foundation
import UserNotifications

/// ローカル通知の許可とスケジュール/キャンセルを担う。
/// 次回対策・設置の予定日時にリマインド通知を出す。
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    // 通知アクション用のカテゴリ／アクション識別子
    static let categoryID = "PEST_REMINDER"
    static let doneActionID = "DONE"
    static let snoozeActionID = "SNOOZE"

    /// 通知に「完了」「1時間後に再通知」アクションを付けるカテゴリを登録する。起動時に1回呼ぶ。
    func registerCategories() {
        let done = UNNotificationAction(identifier: Self.doneActionID, title: "完了", options: [])
        let snooze = UNNotificationAction(identifier: Self.snoozeActionID, title: "1時間後に再通知", options: [])
        let category = UNNotificationCategory(
            identifier: Self.categoryID,
            actions: [done, snooze],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category])
    }

    /// スケジュール結果。失敗理由を呼び出し側に伝えてユーザーに案内できるようにする。
    enum ScheduleOutcome {
        case scheduled(id: String)
        case notAuthorized   // 通知が許可されていない
        case invalidDate     // 過去の日時
        case failed          // その他の失敗
    }

    /// 予定日時に通知をスケジュールする。既存の通知があれば置き換える。
    func schedule(title: String, body: String, at date: Date, existingID: String?) async -> ScheduleOutcome {
        if let existingID { cancel(id: existingID) }
        guard date > Date() else { return .invalidDate }
        guard await ensureAuthorized() else { return .notAuthorized }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = Self.categoryID

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let id = UUID().uuidString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await center.add(request)
            return .scheduled(id: id)
        } catch {
            return .failed
        }
    }

    /// 指定IDの保留中通知をキャンセルする。
    func cancel(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// 通知が明示的に拒否されているか（リマインド一覧で設定誘導バナーを出すため）。
    func isDenied() async -> Bool {
        await center.notificationSettings().authorizationStatus == .denied
    }

    /// 必要に応じて許可をリクエストし、利用可能かを返す。
    private func ensureAuthorized() async -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }
}
