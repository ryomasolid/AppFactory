import SwiftData
import SwiftUI

@main
struct KameChoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let container: ModelContainer

    init() {
        // 見本（-sample）は端末の記録をさわらないよう、メモリの中で動かす。
        let configuration = ModelConfiguration(isStoredInMemoryOnly: Sample.isOn)
        do {
            container = try ModelContainer(for: Schema(Schema1.models), configurations: [configuration])
        } catch {
            fatalError("記録を開けませんでした: \(error)")
        }
        if Sample.isOn { Sample.fill(container.mainContext) }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Palette.moss)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            guard phase != .inactive else { return }
            let context = container.mainContext
            Task { await Reminders.refresh(context) }
        }
    }
}

struct RootView: View {
    @Query(sort: \Turtle.order) private var turtles: [Turtle]
    @State private var tab = Sample.startTab
    @State private var ads = AdGate()

    var body: some View {
        if turtles.isEmpty {
            WelcomeScreen()
        } else {
            // バナーは各タブの中に置く（TabView の外に置くと iOS 26 のタブバーと重なる）。
            TabView(selection: $tab) {
                TodayScreen().adStrip(ads)
                    .tabItem { Label("きょう", systemImage: "leaf") }.tag(0)
                GrowthScreen().adStrip(ads)
                    .tabItem { Label("成長", systemImage: "chart.xyaxis.line") }.tag(1)
                GearScreen().adStrip(ads)
                    .tabItem { Label("器具", systemImage: "lightbulb") }.tag(2)
                SettingsScreen().adStrip(ads)
                    .tabItem { Label("設定", systemImage: "gearshape") }.tag(3)
            }
            .task { await ads.prepare() }
        }
    }
}

/// 画面上で選んでいるカメ（何匹もいるとき）。
enum Selection {
    static let storageKey = "selected.turtle"

    static func pick(_ turtles: [Turtle], key: String) -> Turtle? {
        turtles.first { $0.key.uuidString == key } ?? turtles.first
    }
}
