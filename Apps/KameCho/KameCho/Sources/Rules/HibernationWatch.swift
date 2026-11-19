import Foundation

/// 冬眠中の体重の減り。ひと月に 1% までが目安で、それより減るなら起こすことを考える。
enum HibernationWatch {
    enum Level: Equatable {
        case fine, careful, wake
    }

    struct Result: Equatable {
        /// 始めたときからの減り（%）。
        let lostPercent: Double
        /// 30日あたりの減り（%）。
        let perMonth: Double
        let level: Level
    }

    static func check(startGrams: Double, startedOn: Date, grams: Double, on: Date, calendar: Calendar = .current) -> Result? {
        guard startGrams > 0, on >= startedOn else { return nil }
        let lost = max(0, (startGrams - grams) / startGrams * 100)
        let days = Double(calendar.dateComponents([.day], from: startedOn, to: on).day ?? 0)
        // 計りはじめの数日は誤差が大きいので、最低2週間ぶんとして割る。
        let perMonth = lost / max(days, 14) * 30
        let level: Level
        if lost >= 10 || perMonth > 2 {
            level = .wake
        } else if perMonth > 1 {
            level = .careful
        } else {
            level = .fine
        }
        return Result(lostPercent: lost, perMonth: perMonth, level: level)
    }

    static func check(_ rest: Rest, measures: [Measure], calendar: Calendar = .current) -> Result? {
        guard let start = rest.startGrams else { return nil }
        let after = measures.filter { $0.on >= rest.startedOn && $0.grams != nil }.max { $0.on < $1.on }
        guard let after, let grams = after.grams else { return nil }
        return check(startGrams: start, startedOn: rest.startedOn, grams: grams, on: after.on, calendar: calendar)
    }
}
