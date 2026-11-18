import SwiftData
import SwiftUI

@main
struct MudaZeroApp: App {
    @Environment(\.scenePhase) private var phase
    private let store: ModelContainer

    init() {
        // 見本（-demo）はメモリの中だけ。端末の記録にはさわらない。
        let config = ModelConfiguration(isStoredInMemoryOnly: Demo.on)
        do {
            store = try ModelContainer(for: Schema(Schema1.all), configurations: [config])
        } catch {
            fatalError("記録の保存場所を開けませんでした: \(error)")
        }
        if Demo.on { Demo.seed(store.mainContext) }
    }

    var body: some Scene {
        WindowGroup {
            Root().tint(Hue.mint)
        }
        .modelContainer(store)
        .onChange(of: phase) { _, now in
            guard now == .background || now == .active else { return }
            let context = store.mainContext
            Task { await Notice.reschedule(context) }
        }
    }
}

struct Root: View {
    @AppStorage(Plan.startedKey) private var started = false
    @State private var tab = Demo.firstTab
    @State private var ads = AdsReady()

    var body: some View {
        if !started {
            Hello()
        } else {
            // バナーはタブごとに付ける（TabView 全体に付けると iOS 26 のタブバーにかぶる）。
            TabView(selection: $tab) {
                TodayTab().withBanner(ads).tabItem { Label("きょう", systemImage: "yensign.circle") }.tag(0)
                MonthTab().withBanner(ads).tabItem { Label("カレンダー", systemImage: "calendar") }.tag(1)
                SettingsTab().withBanner(ads).tabItem { Label("設定", systemImage: "gearshape") }.tag(2)
            }
            .task { await ads.start() }
        }
    }
}
