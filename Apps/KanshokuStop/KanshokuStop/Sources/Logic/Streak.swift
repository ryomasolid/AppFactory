import Foundation

/// 「間食しなかった日」の連続記録。
enum Streak {
    /// いまの連続記録。今日が「しなかった」なら今日まで、今日がまだ未記録なら昨日までを数える。
    /// 今日「しちゃった」なら 0。
    static func current(_ entries: [String: DayEntry], today: Date, calendar: Calendar = .current) -> Int {
        let todayKey = DayKey.of(today, calendar: calendar)
        var day: Date
        switch entries[todayKey]?.status ?? .none {
        case .snacked: return 0
        case .skipped: day = today
        case .none:
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return 0 }
            day = yesterday
        }
        var count = 0
        while entries[DayKey.of(day, calendar: calendar)]?.status == .skipped {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    /// 最長の連続記録（今日より先の日付は数えない）。
    static func best(_ entries: [String: DayEntry], today: Date, calendar: Calendar = .current) -> Int {
        let todayKey = DayKey.of(today, calendar: calendar)
        let days = entries
            .filter { $0.value.status == .skipped && $0.key <= todayKey }
            .compactMap { DayKey.date($0.key, calendar: calendar) }
            .sorted()
        var best = 0
        var run = 0
        var last: Date?
        for day in days {
            if let last, calendar.dateComponents([.day], from: last, to: day).day == 1 {
                run += 1
            } else {
                run = 1
            }
            best = max(best, run)
            last = day
        }
        return best
    }

    /// その月の「しなかった」「しちゃった」の日数。
    static func monthTally(_ entries: [String: DayEntry], month: Date, calendar: Calendar = .current) -> (skipped: Int, snacked: Int) {
        let prefix = String(DayKey.of(month, calendar: calendar).prefix(6))
        var skipped = 0
        var snacked = 0
        for (key, entry) in entries where key.hasPrefix(prefix) {
            if entry.status == .skipped { skipped += 1 }
            if entry.status == .snacked { snacked += 1 }
        }
        return (skipped, snacked)
    }
}
