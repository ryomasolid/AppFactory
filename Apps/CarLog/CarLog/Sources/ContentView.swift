import SwiftData
import SwiftUI

enum AppTab: String {
    case home
    case fuel
    case cost
    case maintenance
    case settings
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(StorageKey.hasSeenOnboarding) private var hasSeenOnboarding = false
    @Query(sort: [SortDescriptor(\Vehicle.sortOrder), SortDescriptor(\Vehicle.createdAt)])
    private var vehicles: [Vehicle]

    @State private var store = StoreManager()
    @State private var selection: AppTab = .home
    @State private var launchSheet: LaunchSheet?
    @State private var showOnboarding = false

    /// 起動引数から直接開く画面（スクショ撮影・レイアウト確認用）。
    private enum LaunchSheet: String, Identifiable {
        case paywall
        case fuelEntry
        var id: String { rawValue }
    }

    /// 無料版で、撮影用の -hideAds が無いときだけ広告を出す。
    private var showsAds: Bool { !store.isPro && !Launch.hideAds }

    var body: some View {
        // バナーは各タブの中身の一番下（タブバーのすぐ上）に置く。
        // TabView の外（下）に並べると、iOS 26 の浮いたタブバーが削られて広告に接し、
        // AdMob で「広告に重なるコンテンツ」と判定される（はむはむ日記で実際に制限された）。
        TabView(selection: $selection) {
            HomeView(onShowMaintenance: { selection = .maintenance })
                .bannerAd(showsAds)
                .tabItem { Label("ホーム", systemImage: "gauge.with.dots.needle.67percent") }
                .tag(AppTab.home)

            FuelListView()
                .bannerAd(showsAds)
                .tabItem { Label("給油", systemImage: "fuelpump.fill") }
                .tag(AppTab.fuel)

            ExpenseListView()
                .bannerAd(showsAds)
                .tabItem { Label("費用", systemImage: "yensign.circle") }
                .tag(AppTab.cost)

            MaintenanceListView()
                .bannerAd(showsAds)
                .tabItem { Label("メンテ", systemImage: "wrench.and.screwdriver") }
                .tag(AppTab.maintenance)

            SettingsView()
                .bannerAd(showsAds)
                .tabItem { Label("設定", systemImage: "gearshape") }
                .tag(AppTab.settings)
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
            if Launch.showFuelEntry { launchSheet = .fuelEntry }
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
                case .fuelEntry:
                    if let vehicle = vehicles.first {
                        FuelEntryView(vehicle: vehicle, record: nil)
                    }
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
        .modelContainer(
            for: [Vehicle.self, FuelRecord.self, ExpenseRecord.self, MaintenanceItem.self, MaintenanceLog.self],
            inMemory: true
        )
}
