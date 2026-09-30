import SwiftData
import SwiftUI

@main
struct HamuhamuDiaryApp: App {
    @Environment(\.scenePhase) private var scenePhase

    /// 記録・プロフィール・消耗品・献立などを SwiftData で端末内に保存する。
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Schema(AppSchema.models))
        } catch {
            fatalError("SwiftData の初期化に失敗しました: \(error)")
        }
        // 最初の画面を描く前に済ませる（旧版から引き継いだ日記が最初から見えるように）。
        let context = modelContainer.mainContext
        DiaryData.bootstrapIfNeeded(context)
        if Launch.isDemo { Launch.seedIfNeeded(context) }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, phase in
            // 起動・復帰のたびに組み直す。許可ダイアログはここでは出さない（設定画面でだけ求める）。
            guard phase == .active else { return }
            let context = modelContainer.mainContext
            Task { await NotificationScheduler.shared.rebuild(context: context) }
        }
    }
}
