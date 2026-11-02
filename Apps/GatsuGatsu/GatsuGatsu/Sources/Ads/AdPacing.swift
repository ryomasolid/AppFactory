import Foundation

/// 全画面広告（インタースティシャル・アプリ起動）をいつ出してよいかの決まり。
/// 広告は長く使ってもらうほど稼げるので、記事を読み終えた切れ目だけに絞り、数を抑える。
/// SDK から切り離してあるので、ここだけでテストできる。
struct AdPacing: Equatable, Codable {
    /// インタースティシャルまでに読み終える画面の数。
    static let pagesPerInterstitial = 3
    /// 全画面広告どうしの最小の間隔。
    static let minimumGap: TimeInterval = 3 * 60
    /// 起動してしばらくは全画面広告を出さない。
    static let launchGrace: TimeInterval = 90
    /// 1日に出すインタースティシャルの上限。
    static let dailyInterstitialCap = 6
    /// アプリ起動広告を出す、離れていた時間の下限。Googleマップを見て戻ったくらいでは出さない。
    static let appOpenMinimumAway: TimeInterval = 30 * 60
    /// アプリ起動広告どうしの間隔。
    static let appOpenGap: TimeInterval = 4 * 60 * 60
    /// 初めて使う人には出さない。これ未満の起動回数では出さない。
    static let appOpenMinimumLaunches = 3

    var launchedAt: Date = .distantPast
    var launchCount = 0
    var pagesSinceFullScreen = 0
    var lastFullScreen: Date = .distantPast
    var lastAppOpen: Date = .distantPast
    var interstitialDay: Date = .distantPast
    var interstitialsToday = 0

    mutating func noteLaunch(now: Date = .now) {
        launchedAt = now
        launchCount += 1
    }

    mutating func notePageFinished() { pagesSinceFullScreen += 1 }

    func allowsInterstitial(now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard pagesSinceFullScreen >= Self.pagesPerInterstitial,
              now.timeIntervalSince(launchedAt) >= Self.launchGrace,
              now.timeIntervalSince(lastFullScreen) >= Self.minimumGap else { return false }
        return !calendar.isDate(interstitialDay, inSameDayAs: now) || interstitialsToday < Self.dailyInterstitialCap
    }

    func allowsAppOpen(awayFor away: TimeInterval, now: Date = .now) -> Bool {
        launchCount >= Self.appOpenMinimumLaunches
            && away >= Self.appOpenMinimumAway
            && now.timeIntervalSince(lastAppOpen) >= Self.appOpenGap
            && now.timeIntervalSince(lastFullScreen) >= Self.minimumGap
    }

    mutating func noteInterstitialShown(now: Date = .now, calendar: Calendar = .current) {
        if calendar.isDate(interstitialDay, inSameDayAs: now) {
            interstitialsToday += 1
        } else {
            interstitialDay = now
            interstitialsToday = 1
        }
        noteFullScreen(now: now)
    }

    mutating func noteAppOpenShown(now: Date = .now) {
        lastAppOpen = now
        noteFullScreen(now: now)
    }

    /// リワードも含め、全画面の広告を出したあと。
    mutating func noteFullScreen(now: Date = .now) {
        lastFullScreen = now
        pagesSinceFullScreen = 0
    }
}
