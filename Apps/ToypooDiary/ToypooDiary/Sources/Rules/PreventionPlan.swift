import Foundation

/// 予防の次の予定。ワクチン・健康診断は1年ごと、フィラリア・ノミダニは「シーズン中に毎月」。
enum PreventionPlan {
    /// 毎月の薬を飲ませる（つける）月。start〜end（年をまたいでもよい）。
    struct Season: Equatable, Codable {
        var start: Int
        var end: Int

        static let heartwormDefault = Season(start: 5, end: 12)
        static let fleaTickDefault = Season(start: 3, end: 12)
        static let allYear = Season(start: 1, end: 12)

        func contains(month: Int) -> Bool {
            start <= end ? (start...end).contains(month) : (month >= start || month <= end)
        }

        var isAllYear: Bool { (start == 1 && end == 12) || end + 1 == start }

        var text: String { isAllYear ? "1年じゅう" : "\(start)月〜\(end)月" }
    }

    static func next(kind: CareKind, last: Date?, season: Season, today now: Date, calendar: Calendar = .current) -> Date? {
        let today = calendar.startOfDay(for: now)
        guard kind.isMonthly else {
            return last.flatMap { calendar.date(byAdding: .year, value: 1, to: calendar.startOfDay(for: $0)) }
        }
        guard let last else {
            return season.contains(month: calendar.component(.month, from: today)) ? today : seasonStart(onOrAfter: today, season: season, calendar: calendar)
        }
        let candidate = calendar.date(byAdding: .month, value: 1, to: calendar.startOfDay(for: last))!
        if candidate >= today {
            return season.contains(month: calendar.component(.month, from: candidate))
                ? candidate
                : seasonStart(onOrAfter: candidate, season: season, calendar: calendar)
        }
        // 過ぎている。いまがシーズン外なら次のシーズンの初め、シーズン中なら（今シーズンの分だけ）遅れとして出す。
        guard season.contains(month: calendar.component(.month, from: today)) else {
            return seasonStart(onOrAfter: today, season: season, calendar: calendar)
        }
        return max(candidate, currentSeasonStart(containing: today, season: season, calendar: calendar))
    }

    /// その日以後で いちばん早い「シーズン初めの月の1日」。
    static func seasonStart(onOrAfter day: Date, season: Season, calendar: Calendar = .current) -> Date {
        let parts = calendar.dateComponents([.year, .month], from: day)
        var year = parts.year!
        if parts.month! > season.start || (parts.month! == season.start && calendar.component(.day, from: day) > 1) { year += 1 }
        return calendar.date(from: DateComponents(year: year, month: season.start, day: 1))!
    }

    /// いまのシーズンが始まった月の1日。
    static func currentSeasonStart(containing day: Date, season: Season, calendar: Calendar = .current) -> Date {
        var first = calendar.date(from: calendar.dateComponents([.year, .month], from: day))!
        for _ in 0..<11 {
            let previous = calendar.date(byAdding: .month, value: -1, to: first)!
            guard season.contains(month: calendar.component(.month, from: previous)) else { break }
            first = previous
        }
        return first
    }

    static func daysLeft(until due: Date, from now: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: due)).day ?? 0
    }
}

/// 設定で変えられるシーズン（UserDefaults）。
enum SeasonSetting {
    static func key(_ kind: CareKind) -> String { "season.\(kind.rawValue)" }

    static func load(_ kind: CareKind, defaults: UserDefaults = .standard) -> PreventionPlan.Season {
        if let data = defaults.data(forKey: key(kind)), let season = try? JSONDecoder().decode(PreventionPlan.Season.self, from: data) {
            return season
        }
        return kind == .fleaTick ? .fleaTickDefault : .heartwormDefault
    }

    static func save(_ season: PreventionPlan.Season, for kind: CareKind, defaults: UserDefaults = .standard) {
        defaults.set(try? JSONEncoder().encode(season), forKey: key(kind))
    }
}
