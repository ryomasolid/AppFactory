import SwiftUI

@main
struct KanshokuStopApp: App {
    @State private var book: SnackBook = Sample.isOn ? Sample.book() : SnackBook.open()

    var body: some Scene {
        WindowGroup {
            MainTabs()
                .environment(book)
                .tint(Palette.leaf)
        }
    }
}

struct MainTabs: View {
    @State private var selection = Sample.firstTab
    @State private var consent = AdConsent()

    var body: some View {
        // 広告の帯はタブごとに付ける（TabView 全体に付けると iOS 26 のタブバーが隠れる）。
        TabView(selection: $selection) {
            TodayScreen()
                .adStrip(consent, unit: .today)
                .tabItem { Label("きょう", systemImage: "checkmark.circle") }
                .tag(0)
            CalendarScreen()
                .adStrip(consent, unit: .calendar)
                .tabItem { Label("カレンダー", systemImage: "calendar") }
                .tag(1)
        }
        .task { await consent.begin() }
    }
}

/// 「間食しなかった」が 5 日たまった人にだけ App Store の評価をお願いする。
/// 一度お願いしたら 100 日はあける（OS 側にも回数制限がある）。
enum ReviewAsk {
    static let minSkippedDays = 5
    static let interval: TimeInterval = 100 * 24 * 60 * 60
    private static let lastKey = "lastReviewRequest"

    static func shouldAsk(skippedDays: Int, now: Date = .now, defaults: UserDefaults = .standard) -> Bool {
        guard !ProcessInfo.processInfo.arguments.contains("-quiet"), skippedDays >= minSkippedDays else { return false }
        let last = defaults.double(forKey: lastKey)
        return last == 0 || now.timeIntervalSince1970 - last >= interval
    }

    static func markAsked(now: Date = .now, defaults: UserDefaults = .standard) {
        defaults.set(now.timeIntervalSince1970, forKey: lastKey)
    }
}
