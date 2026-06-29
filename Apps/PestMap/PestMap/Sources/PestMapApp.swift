import SwiftData
import SwiftUI
import UserNotifications

@main
struct PestMapApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    let container: ModelContainer

    init() {
        // 通知アクションのハンドラからも使えるよう、コンテナを1つ作って共有する。
        container = try! ModelContainer(for: FloorPlan.self, PestMarker.self, DoneRecord.self)
        AppDelegate.sharedContainer = container
    }

    var body: some Scene {
        WindowGroup {
            FloorPlanListView()
        }
        .modelContainer(container)
    }
}

/// 通知のフォアグラウンド表示と、通知アクション（完了/スヌーズ）の処理を担う。
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static var sharedContainer: ModelContainer?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationService.shared.registerCategories()
        return true
    }

    /// アプリ前面でも通知を表示する（未実装だと起動中はバナーが出ない）。
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    /// 通知のアクション（完了/スヌーズ）に応答する。
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await handle(response)
    }

    @MainActor
    private func handle(_ response: UNNotificationResponse) async {
        guard let container = Self.sharedContainer else { return }
        let context = container.mainContext
        let notificationID = response.notification.request.identifier

        let markers = (try? context.fetch(FetchDescriptor<PestMarker>())) ?? []
        guard let marker = markers.first(where: { $0.notificationID == notificationID }) else { return }

        switch response.actionIdentifier {
        case NotificationService.doneActionID:
            let record = DoneRecord(date: Date())
            record.marker = marker
            context.insert(record)
            marker.lastDoneDate = record.date
            if let next = marker.repeatInterval.nextDate(from: record.date) {
                await reschedule(marker, to: next, existingID: notificationID)
            } else {
                marker.nextActionDate = nil
                marker.notificationID = nil
            }
        case NotificationService.snoozeActionID:
            let next = Date().addingTimeInterval(3600)
            await reschedule(marker, to: next, existingID: notificationID)
        default:
            break
        }
        try? context.save()
    }

    @MainActor
    private func reschedule(_ marker: PestMarker, to date: Date, existingID: String) async {
        let note = marker.note.isEmpty ? "" : "（\(marker.note)）"
        let planName = marker.plan?.name ?? ""
        let outcome = await NotificationService.shared.schedule(
            title: String(localized: "害虫対策のリマインド"),
            body: "\(planName)：\(marker.kind.label)\(note)",
            at: date,
            existingID: existingID
        )
        if case .scheduled(let id) = outcome {
            marker.nextActionDate = date
            marker.notificationID = id
        }
    }
}
