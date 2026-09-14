import SwiftData
import SwiftUI

@main
struct WarrantyPocketApp: App {
    @Environment(\.scenePhase) private var scenePhase

    /// 商品と写真を SwiftData で端末内に保存する。
    let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Item.self, Attachment.self)
        } catch {
            fatalError("SwiftData の初期化に失敗しました: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, phase in
            // 起動・復帰のたびに組み直す。予約は近い順に60件までなので、日が進むと遠い期限が順に入る。
            // ここでは許可ダイアログを出さない（許可はオンボーディングと設定でだけ求める）。
            guard phase == .active else { return }
            let context = modelContainer.mainContext
            Task { await NotificationScheduler.shared.rebuild(context: context) }
        }
    }
}
