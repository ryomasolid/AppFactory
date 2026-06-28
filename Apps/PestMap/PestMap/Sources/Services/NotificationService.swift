import Foundation
import UserNotifications

/// ローカル通知の許可とスケジュール/キャンセルを担う。
/// 次回対策・設置の予定日時にリマインド通知を出す。
final class NotificationService {
    static let shared = NotificationService()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    /// 予定日時に通知をスケジュールする。既存の通知があれば置き換える。
    /// - Returns: スケジュールした通知の識別子（失敗・過去日時なら nil）。
    func schedule(title: String, body: String, at date: Date, existingID: String?) async -> String? {
        if let existingID { cancel(id: existingID) }
        guard date > Date() else { return nil }
        guard await ensureAuthorized() else { return nil }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute], from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let id = UUID().uuidString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        do {
            try await center.add(request)
            return id
        } catch {
            return nil
        }
    }

    /// 指定IDの保留中通知をキャンセルする。
    func cancel(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
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
