import StoreKit
import SwiftData
import SwiftUI

enum AppTab: String {
    case home
    case diary
    case profile
    case settings
}

struct ContentView: View {
    @Environment(\.requestReview) private var requestReview
    @Query(sort: \DiaryRecord.date, order: .reverse) private var records: [DiaryRecord]
    @Query private var profiles: [HamsterProfile]
    @AppStorage(StorageKey.reviewRequestedCount) private var reviewRequestedCount = 0
    @AppStorage(StorageKey.reviewRequestedAt) private var reviewRequestedAt = 0.0

    @State private var selection: AppTab = .home
    @State private var adPermission = AdPermission()
    @State private var launchSheet: LaunchSheet?

    /// 起動引数から直接開く画面（スクショ撮影・レイアウト確認用）。
    private enum LaunchSheet: String, Identifiable {
        case recordEntry
        case shareCard
        /// ウィジェットから。今日の記録があればその編集、無ければ新しい記録。
        case todayRecord
        var id: String { rawValue }
    }

    var body: some View {
        // 広告は各タブの中身の一番下（タブバーのすぐ上）に置く。記録の保存などの途中には出さない。
        // TabView の外（下）に並べると、iOS 26 の浮いたタブバーが削られて切れ、広告のすぐ上に
        // タブや中身がはみ出す（AdMob で「広告に重なるコンテンツ」と判定された）。
        TabView(selection: $selection) {
            HomeView(onShowDiary: { selection = .diary })
                .adStrip(adPermission)
                .tabItem { Label("ホーム", systemImage: "house.fill") }
                .tag(AppTab.home)

            DiaryView()
                .adStrip(adPermission)
                .tabItem { Label("日記", systemImage: "book.fill") }
                .tag(AppTab.diary)

            ProfileView()
                .adStrip(adPermission)
                .tabItem { Label("プロフィール", systemImage: "pawprint.fill") }
                .tag(AppTab.profile)

            SettingsView()
                .adStrip(adPermission)
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .background(Theme.background.ignoresSafeArea())
        .tint(Theme.accent)
        .onAppear {
            if let tab = Launch.startTab.flatMap(AppTab.init(rawValue:)) { selection = tab }
            if Launch.showRecordEntry { launchSheet = .recordEntry }
            if Launch.showShareCard { launchSheet = .shareCard }
        }
        .task { await adPermission.begin() }
        .onOpenURL { url in
            guard url == WidgetSnapshot.recordURL else { return }
            selection = .home
            launchSheet = .todayRecord
        }
        .onChange(of: records.count) { old, new in
            // 記録が増えたときだけ判定する（削除や起動直後の読み込みでは出さない）。
            guard new > old else { return }
            let lastAt = reviewRequestedAt > 0 ? Date(timeIntervalSince1970: reviewRequestedAt) : nil
            let atMilestone = ReviewPolicy.shouldRequest(
                recordCount: new, lastRequestedCount: reviewRequestedCount, lastRequestedAt: lastAt
            )
            let isAnniversary = profiles.first.map {
                !Anniversaries.on(Date(), birthDate: $0.birthDate, welcomeDate: $0.welcomeDate).isEmpty
            } ?? false
            guard atMilestone || (isAnniversary && ReviewPolicy.shouldRequestAtHappyMoment(lastRequestedAt: lastAt)) else { return }
            if atMilestone { reviewRequestedCount = new }
            reviewRequestedAt = Date().timeIntervalSince1970
            // 保存のシートが閉じきってから出す。
            Task {
                try? await Task.sleep(for: .seconds(1.2))
                requestReview()
            }
        }
        .sheet(item: $launchSheet) { sheet in
            switch sheet {
            case .recordEntry:
                RecordEditorView(record: nil)
            case .shareCard:
                if let record = records.first {
                    ShareCardView(record: record)
                }
            case .todayRecord:
                RecordEditorView(record: records.first { Calendar.current.isDateInToday($0.date) })
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: AppSchema.models, inMemory: true)
}
