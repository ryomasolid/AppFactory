import SwiftData
import SwiftUI

/// TODO: 本実装では「カレンダー」「設定」タブを足して4タブにする（`Docs/Design.md` 5章）。
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selection = 0
    @State private var launchSheet: LaunchSheet?

    /// 起動引数から直接開く画面（スクショ撮影・レイアウト確認用）。
    private enum LaunchSheet: String, Identifiable {
        case ruleEditor
        case kindEditor
        var id: String { rawValue }
    }

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house.fill") }
                .tag(0)

            ScheduleListView()
                .tabItem { Label("予定", systemImage: "list.bullet.rectangle") }
                .tag(1)
        }
        .tint(Theme.accent)
        .onAppear {
            NotificationScheduler.shared.registerCategories()
            if Launch.isDemo { Launch.seedIfNeeded(modelContext) }
            if Launch.startTab == "schedule" { selection = 1 }
            if Launch.showRuleEditor { launchSheet = .ruleEditor }
            if Launch.showKindEditor { launchSheet = .kindEditor }
        }
        .sheet(item: $launchSheet) { sheet in
            // 起動引数から直接開いたときは保存先が無いので、内容は破棄する。
            switch sheet {
            case .ruleEditor:
                RuleEditorView(
                    spec: RuleSpec(
                        frequency: .nthWeekday, weekdays: [.wednesday], nthWeeks: [.second, .fourth]
                    ),
                    onSave: { _ in },
                    onDelete: {}
                )
            case .kindEditor:
                KindEditorView(
                    title: "種類を編集", draft: Launch.demoDraft, onSave: { _ in }, onDelete: {}
                )
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [GarbageKind.self, CollectionRule.self, DoneRecord.self], inMemory: true)
}
