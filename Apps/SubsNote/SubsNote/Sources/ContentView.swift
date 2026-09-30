import SwiftData
import SwiftUI

/// 下のタブ。並びは「いま払っているもの → いつ払うか → やめるか → 設定」の順。
enum AppTab: String, CaseIterable {
    case home
    case calendar
    case review
    case settings

    var title: LocalizedStringKey {
        switch self {
        case .home: "ホーム"
        case .calendar: "カレンダー"
        case .review: "見直し"
        case .settings: "設定"
        }
    }

    var symbol: String {
        switch self {
        case .home: "list.bullet.rectangle.portrait.fill"
        case .calendar: "calendar"
        case .review: "scalemass.fill"
        case .settings: "gearshape"
        }
    }
}

/// アプリの外枠。タブ・無料版のバナー・初回の案内・起動引数で開く画面をまとめる。
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(StorageKey.hasSeenOnboarding) private var hasSeenOnboarding = false

    @State private var pro = ProUnlock()
    @State private var tab: AppTab = .home
    @State private var shortcut: Shortcut?
    @State private var isOnboarding = false

    /// 起動引数から直接開くシート（スクショ撮影・レイアウト確認用）。
    private enum Shortcut: String, Identifiable {
        case paywall, presetPicker
        var id: Self { self }
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $tab) {
                ForEach(AppTab.allCases, id: \.self) { item in
                    screen(for: item)
                        .tabItem { Label(item.title, systemImage: item.symbol) }
                        .tag(item)
                }
            }
            // バナーはタブバーの下に1つだけ（画面ごとに置くと切り替えのたびに読み込み直す）。
            if !pro.isUnlocked, !Launch.hideAds { FooterAd() }
        }
        .environment(pro)
        .tint(Palette.ink)
        .onAppear(perform: applyLaunchOptions)
        .sheet(item: $shortcut) { item in
            // シートには @Observable の環境が伝わらないので、ProUnlock を明示的に渡す。
            Group {
                if item == .paywall { PaywallView() } else { AddSubscriptionSheet(preset: nil) }
            }
            .environment(pro)
        }
        .fullScreenCover(isPresented: $isOnboarding) {
            OnboardingView(onDone: finishOnboarding).environment(pro)
        }
    }

    @ViewBuilder
    private func screen(for item: AppTab) -> some View {
        switch item {
        case .home: HomeView()
        case .calendar: BillingCalendarView()
        case .review: ReviewView()
        case .settings: SettingsView()
        }
    }

    private func applyLaunchOptions() {
        if Launch.isDemo {
            Launch.seedIfNeeded(modelContext)
            hasSeenOnboarding = true  // デモ（スクショ撮影）は案内を飛ばす
        }
        if let start = Launch.startTab.flatMap(AppTab.init(rawValue:)) { tab = start }
        shortcut = Launch.showPaywall ? .paywall : (Launch.showPresetPicker ? .presetPicker : nil)
        isOnboarding = !hasSeenOnboarding || Launch.forceOnboarding
        // 同意・ATT のダイアログは案内のあとに出す（通知の許可と重ねない）。
        if !isOnboarding { AdStartup.runOnce() }
    }

    private func finishOnboarding() {
        hasSeenOnboarding = true
        isOnboarding = false
        AdStartup.runOnce()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Subscription.self, inMemory: true)
}
