import SwiftData
import SwiftUI
import UserNotifications

@main
struct PestMapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            FloorPlanListView()
        }
        .modelContainer(for: [FloorPlan.self, PestMarker.self])
    }
}

/// 通知のフォアグラウンド表示を担う。これがないと、アプリを開いている間は
/// 通知バナーが出ない（iOS の既定動作）。
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
