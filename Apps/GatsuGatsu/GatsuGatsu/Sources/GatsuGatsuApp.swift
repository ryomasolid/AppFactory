import SwiftUI
import UserNotifications

@main
struct GatsuGatsuApp: App {
    @State private var navigator = Navigator()
    @State private var ads = AdDirector()
    @State private var cards = SponsoredCardBroker()
    @State private var log = BiteLog()
    @State private var shelf = Shelf()
    @State private var booted = false
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UNUserNotificationCenter.current().delegate = ForegroundReminders.shared
    }

    var body: some Scene {
        WindowGroup {
            RootTabs()
                .environment(navigator)
                .environment(ads)
                .environment(cards)
                .environment(log)
                .environment(shelf)
                .task {
                    // 全画面広告を閉じると、この task がもう一度走る。起動時の処理は1回だけにする。
                    guard !booted else { return }
                    booted = true
                    navigator.applyLaunchArguments()
                    if UserDefaults.standard.bool(forKey: "demoLog") { log.replaceAll(DemoBites.make()) }
                    // 最初の画面を見せてから、同意と ATT に進む。
                    try? await Task.sleep(for: .milliseconds(400))
                    await ads.begin()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            // 通知の許可や ATT のダイアログは inactive どまりなので、ここには来ない。
            switch phase {
            case .background: ads.sceneWentToBackground()
            case .active: ads.sceneCameBack()
            default: break
            }
        }
    }
}

struct RootTabs: View {
    @Environment(Navigator.self) private var navigator

    var body: some View {
        @Bindable var navigator = navigator
        TabView(selection: $navigator.tab) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabStack(tab: tab) { root(of: tab) }
                    .tabItem { Label(tab.title, systemImage: tab.icon) }
                    .tag(tab)
            }
        }
    }

    @ViewBuilder
    private func root(of tab: AppTab) -> some View {
        switch tab {
        case .home: HomeScreen()
        case .stations: StationIndexScreen()
        case .read: ReadScreen()
        case .tools: ToolsScreen()
        case .log: LogScreen()
        }
    }
}
