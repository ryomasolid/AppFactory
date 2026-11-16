import Foundation

/// トリミングの周期。プードルの毛は抜けかわらず伸び続けるので、前回のカットからの日数が大事。
enum TrimRhythm {
    /// 記録が少ないときの目安（月1回）。
    static let fallbackDays = 30
    static let range = 14...90
    /// 1か月でおよそ1cm伸びる。
    static let cmPerDay = 1.0 / 30

    enum Phase: Equatable {
        case noRecord, fresh, growing, soon, overdue
    }

    struct Status: Equatable {
        var lastCut: Date?
        var daysSince: Int?
        var interval: Int
        var nextDue: Date?
        var daysLeft: Int?
        var phase: Phase

        /// 前回からの毛の伸び（cm・小数1けた）。
        var grownCm: Double? {
            daysSince.map { (Double($0) * TrimRhythm.cmPerDay * 10).rounded() / 10 }
        }
    }

    /// 最近（最大5回ぶん）の間隔の真ん中の値。2回目までは目安を使う。
    static func interval(cuts: [Date], calendar: Calendar = .current) -> Int {
        let days = cuts.map { calendar.startOfDay(for: $0) }.sorted()
        let gaps = zip(days, days.dropFirst())
            .compactMap { calendar.dateComponents([.day], from: $0, to: $1).day }
            .filter { $0 > 0 }
            .suffix(5)
            .sorted()
        guard !gaps.isEmpty else { return fallbackDays }
        let middle = gaps.count % 2 == 1
            ? gaps[gaps.count / 2]
            : (gaps[gaps.count / 2 - 1] + gaps[gaps.count / 2]) / 2
        return min(max(middle, range.lowerBound), range.upperBound)
    }

    static func status(cuts: [Date], now: Date, calendar: Calendar = .current) -> Status {
        let step = interval(cuts: cuts, calendar: calendar)
        guard let last = cuts.max() else {
            return Status(interval: step, phase: .noRecord)
        }
        let today = calendar.startOfDay(for: now)
        let lastDay = calendar.startOfDay(for: last)
        let since = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
        let due = calendar.date(byAdding: .day, value: step, to: lastDay)!
        let left = calendar.dateComponents([.day], from: today, to: due).day ?? 0
        let phase: Phase = switch left {
        case ..<0: .overdue
        case ...7: .soon
        default: since <= 7 ? .fresh : .growing
        }
        return Status(lastCut: last, daysSince: since, interval: step, nextDue: due, daysLeft: left, phase: phase)
    }
}
