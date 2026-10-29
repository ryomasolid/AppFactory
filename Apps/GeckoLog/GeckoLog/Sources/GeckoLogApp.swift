import SwiftData
import SwiftUI

@main
struct GeckoLogApp: App {
    @Environment(\.scenePhase) private var scenePhase
    let container: ModelContainer

    init() {
        // スクショ撮影（-showcase）のときは端末の記録に触れないよう、メモリ上だけで動かす。
        let configuration = ModelConfiguration(isStoredInMemoryOnly: Showcase.isOn)
        do {
            container = try ModelContainer(for: Schema(StoreSchema.models), configurations: [configuration])
        } catch {
            fatalError("記録の保存場所を開けませんでした: \(error)")
        }
        if Showcase.isOn { Showcase.fill(container.mainContext) }
    }

    var body: some Scene {
        WindowGroup {
            RootTabs()
                .tint(Terrarium.moss)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            let context = container.mainContext
            Task { await FeedingAlarm.reschedule(context: context) }
        }
    }
}

struct RootTabs: View {
    @State private var tab = Showcase.startTab

    var body: some View {
        TabView(selection: $tab) {
            CageScreen()
                .tabItem { Label("ケージ", systemImage: "square.grid.2x2") }
                .tag(0)
            JournalScreen()
                .tabItem { Label("きろく", systemImage: "list.bullet.rectangle") }
                .tag(1)
            EggScreen()
                .tabItem { Label("たまご", systemImage: "hourglass") }
                .tag(2)
            PrefsScreen()
                .tabItem { Label("せってい", systemImage: "gearshape") }
                .tag(3)
        }
    }
}
