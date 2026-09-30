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
    @AppStorage(StorageKey.reviewRequestedCount) private var reviewRequestedCount = 0
    @AppStorage(StorageKey.reviewRequestedAt) private var reviewRequestedAt = 0.0

    @State private var selection: AppTab = .home
    @State private var adPermission = AdPermission()
    @State private var launchSheet: LaunchSheet?

    /// 起動引数から直接開く画面（スクショ撮影・レイアウト確認用）。
    private enum LaunchSheet: String, Identifiable {
        case recordEntry
        case shareCard
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selection) {
                HomeView(onShowDiary: { selection = .diary })
                    .tabItem { Label("ホーム", systemImage: "house.fill") }
                    .tag(AppTab.home)

                DiaryView()
                    .tabItem { Label("日記", systemImage: "book.fill") }
                    .tag(AppTab.diary)

                ProfileView()
                    .tabItem { Label("プロフィール", systemImage: "pawprint.fill") }
                    .tag(AppTab.profile)

                SettingsView()
                    .tabItem { Label("設定", systemImage: "gearshape.fill") }
                    .tag(AppTab.settings)
            }

            // 広告は全タブ共通の1枠だけ。記録の保存などの途中には出さない。
            AdStrip(permission: adPermission)
        }
        .background(Theme.background.ignoresSafeArea())
        .tint(Theme.accent)
        .onAppear {
            if let tab = Launch.startTab.flatMap(AppTab.init(rawValue:)) { selection = tab }
            if Launch.showRecordEntry { launchSheet = .recordEntry }
            if Launch.showShareCard { launchSheet = .shareCard }
        }
        .task { await adPermission.begin() }
        .onChange(of: records.count) { old, new in
            // 記録が増えたときだけ判定する（削除や起動直後の読み込みでは出さない）。
            guard new > old else { return }
            let lastAt = reviewRequestedAt > 0 ? Date(timeIntervalSince1970: reviewRequestedAt) : nil
            guard ReviewPolicy.shouldRequest(
                recordCount: new, lastRequestedCount: reviewRequestedCount, lastRequestedAt: lastAt
            ) else { return }
            reviewRequestedCount = new
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
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: AppSchema.models, inMemory: true)
}
