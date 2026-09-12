import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("ga.hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var store = StoreManager()
    @State private var selection = 0
    @State private var launchSheet: LaunchSheet?
    @State private var showOnboarding = false

    /// 起動引数から直接開く画面（スクショ撮影・レイアウト確認用）。
    private enum LaunchSheet: String, Identifiable {
        case ruleEditor
        case kindEditor
        case paywall
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selection) {
                HomeView()
                    .tabItem { Label("ホーム", systemImage: "house.fill") }
                    .tag(0)

                ScheduleListView()
                    .tabItem { Label("予定", systemImage: "list.bullet.rectangle") }
                    .tag(1)

                CalendarView()
                    .tabItem { Label("カレンダー", systemImage: "calendar") }
                    .tag(2)

                SettingsView()
                    .tabItem { Label("設定", systemImage: "gearshape") }
                    .tag(3)
            }

            // バナーは全タブ共通で最下部に1つだけ置く。画面ごとに置くと重複や二重表示を招く。
            if !store.isPro, !Launch.hideAds {
                BannerAdView()
            }
        }
        .environment(store)
        .tint(Theme.accent)
        .onAppear {
            NotificationScheduler.shared.registerCategories()
            if Launch.isDemo { Launch.seedIfNeeded(modelContext) }
            switch Launch.startTab {
            case "schedule": selection = 1
            case "calendar": selection = 2
            case "settings": selection = 3
            default: break
            }
            if Launch.showRuleEditor { launchSheet = .ruleEditor }
            if Launch.showKindEditor { launchSheet = .kindEditor }
            if Launch.showPaywall { launchSheet = .paywall }
            // デモ投入時はオンボーディング済み扱いにする（スクショ撮影のため）。
            if Launch.isDemo { hasSeenOnboarding = true }
            showOnboarding = !hasSeenOnboarding || Launch.forceOnboarding
            // 広告の同意（UMP）→ ATT → AdMob 初期化を実行。
            // 広告非表示（スクショ撮影）時は同意フローも走らせない。
            ConsentManager.shared.start()
        }
        .sheet(item: $launchSheet) { sheet in
            // シートの中身には環境が自動で伝わらないので、StoreManager を明示的に渡す。
            // （渡し忘れると PaywallView 表示時に "No Observable object of type StoreManager" で落ちる）
            Group {
                switch sheet {
                case .ruleEditor:
                    // 起動引数から直接開いたときは保存先が無いので、内容は破棄する。
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
                case .paywall:
                    PaywallView()
                }
            }
            .environment(store)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                hasSeenOnboarding = true
                showOnboarding = false
            }
            .environment(store)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [GarbageKind.self, CollectionRule.self, DoneRecord.self], inMemory: true)
}
