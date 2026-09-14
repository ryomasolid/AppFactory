import SwiftData
import SwiftUI

enum AppTab: String {
    case home
    case calendar
    case settings
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(StorageKey.hasSeenOnboarding) private var hasSeenOnboarding = false

    @State private var store = StoreManager()
    @State private var selection: AppTab = .home
    @State private var launchSheet: LaunchSheet?
    @State private var showOnboarding = false

    /// 起動引数から直接開く画面（スクショ撮影・レイアウト確認用）。
    private enum LaunchSheet: String, Identifiable {
        case paywall
        case presetPicker
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selection) {
                HomeView()
                    .tabItem { Label("ホーム", systemImage: "list.bullet.rectangle.portrait.fill") }
                    .tag(AppTab.home)

                BillingCalendarView()
                    .tabItem { Label("カレンダー", systemImage: "calendar") }
                    .tag(AppTab.calendar)

                SettingsView()
                    .tabItem { Label("設定", systemImage: "gearshape") }
                    .tag(AppTab.settings)
            }

            // バナーは全タブ共通で最下部に1つだけ置く。画面ごとに置くと重複や二重表示を招く。
            if !store.isPro, !Launch.hideAds {
                BannerAdView()
            }
        }
        .environment(store)
        .tint(Theme.accent)
        .onAppear {
            if Launch.isDemo {
                Launch.seedIfNeeded(modelContext)
                // デモ投入時はオンボーディング済み扱いにする（スクショ撮影のため）。
                hasSeenOnboarding = true
            }
            if let tab = Launch.startTab.flatMap(AppTab.init(rawValue:)) { selection = tab }
            if Launch.showPresetPicker { launchSheet = .presetPicker }
            if Launch.showPaywall { launchSheet = .paywall }
            showOnboarding = !hasSeenOnboarding || Launch.forceOnboarding
            // 広告の同意（UMP）→ ATT → AdMob 初期化。広告非表示（スクショ撮影）時は走らせない。
            // オンボーディング中にダイアログが重ならないよう、初回は完了後に回す。
            if !showOnboarding { ConsentManager.shared.start() }
        }
        .sheet(item: $launchSheet) { sheet in
            // シートの中身には環境が自動で伝わらないので、StoreManager を明示的に渡す。
            Group {
                switch sheet {
                case .paywall:
                    PaywallView()
                case .presetPicker:
                    AddSubscriptionSheet(preset: nil)
                }
            }
            .environment(store)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                hasSeenOnboarding = true
                showOnboarding = false
                ConsentManager.shared.start()
            }
            .environment(store)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
