import SwiftData
import SwiftUI

@main
struct GomiAlarmApp: App {
    @Environment(\.scenePhase) private var scenePhase

    /// ゴミの種類・収集ルール・「出した」記録を SwiftData で永続化する。
    let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: GarbageKind.self, CollectionRule.self, DoneRecord.self)
        } catch {
            fatalError("SwiftData の初期化に失敗しました: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        // バックグラウンドでの通知再構築。`.backgroundTask` はハンドラ登録・期限切れ処理・
        // 完了通知（setTaskCompleted）を SwiftUI 側が面倒を見てくれるので、AppDelegate を持たずに済む。
        .backgroundTask(.appRefresh(BackgroundRefresh.taskID)) {
            await NotificationRefresh.run(container: modelContainer)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                // 起動・復帰のたびに組み直す。ここでは許可ダイアログを出さない
                // （許可はオンボーディングでだけ求める）。
                Task { await NotificationRefresh.run(container: modelContainer) }
            case .background:
                // バックグラウンド送りの時点で予約が無ければ入れ直す。
                // そのまま終了させられても、次の再構築の機会が残る。
                let status = RefreshStatus.load()
                if !status.isPermanent, status.authorized, status.nextBackgroundRefreshAt == nil {
                    BackgroundRefresh.schedule(at: Date().addingTimeInterval(BackgroundRefreshPolicy.minimumDelay))
                }
            default:
                break
            }
        }
    }
}
