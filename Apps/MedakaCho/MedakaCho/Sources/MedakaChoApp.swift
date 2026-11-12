import SwiftData
import SwiftUI

@main
struct MedakaChoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let container: ModelContainer

    init() {
        // スクショ用の見本（-sample）は端末の記録に触らないよう、メモリの中だけで動かす。
        let config = ModelConfiguration(isStoredInMemoryOnly: Sample.isOn)
        do {
            container = try ModelContainer(for: Schema(StoreModels.all), configurations: [config])
        } catch {
            fatalError("記録の保存場所を開けませんでした: \(error)")
        }
        if Sample.isOn { Sample.plant(in: container.mainContext) }
    }

    var body: some Scene {
        WindowGroup {
            MainTabs()
                .tint(Palette.deep)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            let context = container.mainContext
            Task { await MorningDigest.refresh(context: context) }
        }
    }
}

struct MainTabs: View {
    @State private var selection = Sample.firstTab
    @State private var consent = AdConsent()

    var body: some View {
        // 広告の帯はタブごとに付ける（TabView 全体に付けると iOS 26 のタブバーが隠れる）。
        TabView(selection: $selection) {
            VesselsScreen()
                .adStrip(consent)
                .tabItem { Label("容器", systemImage: "drop.circle") }
                .tag(0)
            EggsScreen()
                .adStrip(consent)
                .tabItem { Label("卵", systemImage: "circle.hexagongrid") }
                .tag(1)
            BreedsScreen()
                .adStrip(consent)
                .tabItem { Label("品種", systemImage: "tag") }
                .tag(2)
            SettingsScreen()
                .adStrip(consent)
                .tabItem { Label("設定", systemImage: "gearshape") }
                .tag(3)
        }
        .task { await consent.begin() }
    }
}
