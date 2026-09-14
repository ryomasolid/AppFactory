import SwiftData
import SwiftUI

@main
struct CarLogApp: App {
    @Environment(\.scenePhase) private var scenePhase

    /// クルマ・給油・費用・メンテ項目・実施履歴を SwiftData で端末内に保存する。
    let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: Vehicle.self, FuelRecord.self, ExpenseRecord.self,
                MaintenanceItem.self, MaintenanceLog.self
            )
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
            // 起動・復帰のたびに組み直す。日付が進むと距離ベースの予測日も動くため。
            // ここでは許可ダイアログを出さない（許可はオンボーディングと設定でだけ求める）。
            guard phase == .active else { return }
            let context = modelContainer.mainContext
            Task { await NotificationScheduler.shared.rebuild(context: context) }
        }
    }
}
