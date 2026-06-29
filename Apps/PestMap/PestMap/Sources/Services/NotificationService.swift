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

    // MARK: - 季節の害虫対策アドバイス（年4回・繰り返し）

    private static let seasonalTips: [(id: String, month: Int, title: String, body: String)] = [
        ("seasonal-spring", 4, "春の害虫対策", "気温が上がりゴキブリが活動を始める季節です。ブラックキャップの設置・交換の好機です。"),
        ("seasonal-rainy", 6, "梅雨の害虫対策", "湿気でダニ・カビが増えやすい時期。除湿・換気とダニ対策を見直しましょう。"),
        ("seasonal-summer", 7, "夏の害虫対策", "蚊やゴキブリが最盛期。設置済みの対策の効き目を確認しましょう。"),
        ("seasonal-autumn", 10, "秋の害虫対策", "越冬前のこの時期の駆除が効果的。来春の発生を抑えられます。"),
    ]

    /// 季節アドバイス通知を毎年繰り返しでスケジュールする。許可が無ければ false。
    func scheduleSeasonalTips() async -> Bool {
        guard await ensureAuthorized() else { return false }
        for tip in Self.seasonalTips {
            var components = DateComponents()
            components.month = tip.month
            components.day = 1
            components.hour = 9
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let content = UNMutableNotificationContent()
            content.title = tip.title
            content.body = tip.body
            content.sound = .default
            let request = UNNotificationRequest(identifier: tip.id, content: content, trigger: trigger)
            try? await center.add(request)
        }
        return true
    }

    /// 季節アドバイス通知を解除する。
    func cancelSeasonalTips() {
        center.removePendingNotificationRequests(withIdentifiers: Self.seasonalTips.map(\.id))
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
