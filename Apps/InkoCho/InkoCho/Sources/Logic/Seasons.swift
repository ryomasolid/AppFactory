import Foundation

/// 換羽と産卵のつづき具合。
enum Seasons {
    /// 換羽が何日つづいているか（今日かきのうまで続いているときだけ数える）。
    static func moltDays(_ marked: [Date], now: Date, calendar: Calendar = .current) -> Int {
        let days = Set(marked.map { calendar.startOfDay(for: $0) })
        var cursor = calendar.startOfDay(for: now)
        if !days.contains(cursor) { cursor = calendar.date(byAdding: .day, value: -1, to: cursor)! }
        var count = 0
        while days.contains(cursor) {
            count += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        return count
    }

    /// 直近14日に産んだ卵の数。
    static func recentEggs(_ eggDays: [Date], now: Date, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: now)
        let from = calendar.date(byAdding: .day, value: -13, to: today)!
        return eggDays.filter { (from...today).contains(calendar.startOfDay(for: $0)) }.count
    }

    /// ペットとして飼っていて卵が続くと、体の負担（カルシウム不足・卵詰まり）が大きい。
    static let eggWarnCount = 3

    /// 直近7日の放鳥の平均（分）。記録した日だけで割る。
    static func outsideAverage(_ entries: [(day: Date, minutes: Int)], now: Date, calendar: Calendar = .current) -> Int? {
        let today = calendar.startOfDay(for: now)
        let from = calendar.date(byAdding: .day, value: -6, to: today)!
        let recent = entries.filter { $0.minutes > 0 && (from...today).contains(calendar.startOfDay(for: $0.day)) }
        guard !recent.isEmpty else { return nil }
        return recent.reduce(0) { $0 + $1.minutes } / recent.count
    }
}
