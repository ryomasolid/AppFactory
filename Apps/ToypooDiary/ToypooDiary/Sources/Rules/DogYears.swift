import Foundation

/// 年齢と「人でいうと何さい」。トイプードル（小型犬）の よく使われる目安に合わせる。
enum DogYears {
    enum Stage: Equatable {
        case puppy, adult, senior
        var label: String {
            switch self {
            case .puppy: "パピー"
            case .adult: "成犬"
            case .senior: "シニア"
            }
        }
    }

    /// 2さいまでは表で、そのあとは1年に4さいずつ。
    private static let early: [(months: Int, human: Double)] = [
        (0, 0), (1, 1), (2, 3), (3, 5), (6, 9), (9, 13), (12, 15), (18, 20), (24, 24),
    ]

    static func months(from birthday: Date, to now: Date, calendar: Calendar = .current) -> Int {
        max(0, calendar.dateComponents([.month], from: calendar.startOfDay(for: birthday), to: calendar.startOfDay(for: now)).month ?? 0)
    }

    static func human(months: Int) -> Int {
        guard months < 24 else { return 24 + (months - 24) * 4 / 12 }
        for (a, b) in zip(early, early.dropFirst()) where months <= b.months {
            let t = Double(months - a.months) / Double(b.months - a.months)
            return Int((a.human + (b.human - a.human) * t).rounded(.down))
        }
        return 24
    }

    /// 小型犬は7さいごろからシニアとして見ることが多い。
    static func stage(months: Int) -> Stage {
        switch months {
        case ..<12: .puppy
        case ..<84: .adult
        default: .senior
        }
    }

    /// 「2さい3か月」「5か月」。
    static func text(months: Int) -> String {
        let y = months / 12, m = months % 12
        if y == 0 { return "\(m)か月" }
        return m == 0 ? "\(y)さい" : "\(y)さい\(m)か月"
    }

    /// 次のお誕生日・うちの子記念日まで何日か（今日なら0）。
    static func daysUntilNext(anniversaryOf date: Date, from now: Date, calendar: Calendar = .current) -> Int {
        let today = calendar.startOfDay(for: now)
        let parts = calendar.dateComponents([.month, .day], from: date)
        guard let next = calendar.nextDate(after: today.addingTimeInterval(-1), matching: parts, matchingPolicy: .nextTime) else { return 0 }
        return calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: next)).day ?? 0
    }
}
