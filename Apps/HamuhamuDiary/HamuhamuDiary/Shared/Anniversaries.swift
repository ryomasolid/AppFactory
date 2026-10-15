import Foundation

/// 誕生日・お迎え日から決まる記念日。通知・ホーム・シェアカード・ウィジェットで使う。
struct Anniversary: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case birthday(years: Int)
        case halfBirthday
        case welcomeDays(Int)
        case welcomeYears(Int)
    }

    /// その日の 0:00。
    var date: Date
    var kind: Kind

    /// 「1歳のお誕生日」など、名前を付けずに使える見出し。
    var label: String {
        switch kind {
        case .birthday(let years): String(localized: "\(years)歳のお誕生日")
        case .halfBirthday: String(localized: "生後半年")
        case .welcomeDays(let days): String(localized: "お迎え\(days)日目")
        case .welcomeYears(let years): String(localized: "お迎え\(years)周年")
        }
    }

    var emoji: String {
        if case .birthday = kind { "🎂" } else { "🎉" }
    }
}

enum Anniversaries {
    /// お迎えからの節目。お迎えの日を1日目と数える（プロフィールの「一緒に過ごして◯日目」と同じ）。
    /// 365日・730日などは「◯周年」として出すので入れない。
    static let welcomeDayMilestones = [30, 100, 200, 300, 500, 800, 1000]
    /// ハムスターの寿命（2〜3年）より少し先まで。
    static let maxYears = 5

    /// `from` の日から `days` 日ぶん（`from` の日を含む）の記念日を日付順に。
    static func between(birthDate: Date?, welcomeDate: Date?, from: Date, days: Int, calendar: Calendar = .current) -> [Anniversary] {
        let start = calendar.startOfDay(for: from)
        guard let end = calendar.date(byAdding: .day, value: days, to: start) else { return [] }
        var result: [Anniversary] = []
        func add(_ date: Date?, _ kind: Anniversary.Kind) {
            guard let date else { return }
            let day = calendar.startOfDay(for: date)
            if day >= start, day < end { result.append(Anniversary(date: day, kind: kind)) }
        }
        if let birthDate {
            let birth = calendar.startOfDay(for: birthDate)
            add(calendar.date(byAdding: .month, value: 6, to: birth), .halfBirthday)
            for years in 1...maxYears { add(calendar.date(byAdding: .year, value: years, to: birth), .birthday(years: years)) }
        }
        if let welcomeDate {
            let welcome = calendar.startOfDay(for: welcomeDate)
            for days in welcomeDayMilestones { add(calendar.date(byAdding: .day, value: days - 1, to: welcome), .welcomeDays(days)) }
            for years in 1...maxYears { add(calendar.date(byAdding: .year, value: years, to: welcome), .welcomeYears(years)) }
        }
        return result.sorted { $0.date < $1.date }
    }

    /// その日の記念日（ふつうは0か1件）。
    static func on(_ day: Date, birthDate: Date?, welcomeDate: Date?, calendar: Calendar = .current) -> [Anniversary] {
        between(birthDate: birthDate, welcomeDate: welcomeDate, from: day, days: 1, calendar: calendar)
    }

    /// 同じ日に重なったときもまとめて1行で出せるように。
    static func label(_ items: [Anniversary]) -> String {
        items.map(\.label).joined(separator: "・")
    }
}
