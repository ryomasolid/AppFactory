import Foundation

/// 散歩と日記のつづき具合。
enum WalkTally {
    struct Week: Equatable {
        var minutes: Int
        var walkedDays: Int
    }

    /// 今日をふくむ7日間。
    static func week(pages: [(day: Date, minutes: Int, count: Int)], now: Date, calendar: Calendar = .current) -> Week {
        let today = calendar.startOfDay(for: now)
        let from = calendar.date(byAdding: .day, value: -6, to: today)!
        let recent = pages.filter { (from...today).contains(calendar.startOfDay(for: $0.day)) }
        return Week(
            minutes: recent.reduce(0) { $0 + $1.minutes },
            walkedDays: Set(recent.filter { $0.count > 0 || $0.minutes > 0 }.map { calendar.startOfDay(for: $0.day) }).count
        )
    }

    /// 日記を何日つづけて書いているか。今日がまだでも、きのうまで続いていれば数える。
    static func streak(days: [Date], now: Date, calendar: Calendar = .current) -> Int {
        let written = Set(days.map { calendar.startOfDay(for: $0) })
        var cursor = calendar.startOfDay(for: now)
        if !written.contains(cursor) { cursor = calendar.date(byAdding: .day, value: -1, to: cursor)! }
        var count = 0
        while written.contains(cursor) {
            count += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        return count
    }
}
