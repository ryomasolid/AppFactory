import SwiftData
import SwiftUI

@main
struct InkoChoApp: App {
    @Environment(\.scenePhase) private var phase
    private let store: ModelContainer

    init() {
        // 見本（-demo）は端末の記録にさわらないよう、メモリの中だけで動かす。
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
            Shell().tint(Hue.sky)
        }
        .modelContainer(store)
        .onChange(of: phase) { _, now in
            guard now == .background || now == .active else { return }
            let context = store.mainContext
            Task { await Alarm.reschedule(context) }
        }
    }
}

struct Shell: View {
    @Query(sort: \Bird.sortIndex) private var birds: [Bird]
    @State private var tab = Demo.firstTab
    @State private var ads = AdsReady()

    var body: some View {
        if birds.isEmpty {
            Hello()
        } else {
            // バナーは各タブの下に付ける（TabView に付けると iOS 26 のタブバーが隠れる）。
            TabView(selection: $tab) {
                TodayTab().withBanner(ads).tabItem { Label("きょう", systemImage: "sun.max") }.tag(0)
                WeightTab().withBanner(ads).tabItem { Label("体重", systemImage: "scalemass") }.tag(1)
                WordsTab().withBanner(ads).tabItem { Label("ことば", systemImage: "text.bubble") }.tag(2)
                ChoresTab().withBanner(ads).tabItem { Label("おせわ", systemImage: "checklist") }.tag(3)
                SettingsTab().withBanner(ads).tabItem { Label("設定", systemImage: "gearshape") }.tag(4)
            }
            .task { await ads.start() }
        }
    }
}

/// いま見ている子（多頭飼いのとき画面上で切りかえる）。
enum Picked {
    static let key = "bird.picked"

    static func bird(in birds: [Bird], tag: String) -> Bird? {
        birds.first { $0.tag.uuidString == tag } ?? birds.first
    }
}
