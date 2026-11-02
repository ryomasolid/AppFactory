import UserNotifications

/// iOS は、アプリを開いている間に届いた通知を既定では表示しない。
/// 行列に並びながらアプリを開いたままでも気づけるよう、前面でもバナーと音を出す。
final class ForegroundReminders: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ForegroundReminders()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
