import SwiftData
import SwiftUI

@main
struct SubsNoteApp: App {
    @Environment(\.scenePhase) private var scenePhase

    /// サブスクを SwiftData で端末内に保存する。
    let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Subscription.self)
        } catch {
            fatalError("SwiftData の初期化に失敗しました: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        // バックグラウンドでの通知の組み直し。`.backgroundTask` はハンドラ登録・期限切れ処理・
        // 完了通知（setTaskCompleted）を SwiftUI 側が面倒を見てくれるので、AppDelegate を持たずに済む。
        .backgroundTask(.appRefresh(BackgroundRefresh.taskID)) {
            await NotificationRefresh.run(container: modelContainer)
        }
        .onChange(of: scenePhase) { _, phase in
            // 起動・復帰のたびに組み直す。予約は近い順に60件までなので、日が進むと先の支払日が順に入る。
            // ここでは許可ダイアログを出さない（許可はオンボーディングと設定でだけ求める）。
            guard phase == .active else { return }
            Task { await NotificationRefresh.run(container: modelContainer) }
        }
    }
}
