import Foundation

/// 曜日。raw 値は Calendar の weekday コンポーネント（1=日曜 … 7=土曜）に揃えてある。
enum Weekday: Int, Codable, CaseIterable, Identifiable, Sendable, Comparable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var id: Int { rawValue }

    /// 「月」「火」…（チップ表示用）。
    var shortLabel: String {
        switch self {
        case .sunday: return String(localized: "日")
        case .monday: return String(localized: "月")
        case .tuesday: return String(localized: "火")
        case .wednesday: return String(localized: "水")
        case .thursday: return String(localized: "木")
        case .friday: return String(localized: "金")
        case .saturday: return String(localized: "土")
        }
    }

    /// 前日の曜日。前夜通知（収集日の前日に鳴らす）で使う。
    var previous: Weekday {
        Weekday(rawValue: rawValue == 1 ? 7 : rawValue - 1) ?? .sunday
    }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }

    static func of(_ date: Date, calendar: Calendar = .current) -> Weekday {
        Weekday(rawValue: calendar.component(.weekday, from: date)) ?? .sunday
    }
}

/// 第n曜日の「第n」。第5週は月によって存在しないため、代わりに `last`（最終◯曜日）を用意している。
enum NthWeek: Int, Codable, CaseIterable, Identifiable, Sendable, Comparable {
    case first = 1
    case second
    case third
    case fourth
    case last = 5

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .first: return String(localized: "第1")
        case .second: return String(localized: "第2")
        case .third: return String(localized: "第3")
        case .fourth: return String(localized: "第4")
        case .last: return String(localized: "最終")
        }
    }

    /// その日付が「第n週」に当たるか。
    /// 第4◯曜日と最終◯曜日は同じ日になることがあり、その場合は両方 true になる（意図どおり）。
    func matches(_ date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.component(.day, from: date)
        if self == .last {
            let lastDay = calendar.range(of: .day, in: .month, for: date)?.count ?? 31
            // 7日後が同じ月に無ければ、その月で最後の同曜日。
            return day + 7 > lastDay
        }
        return (day - 1) / 7 + 1 == rawValue
    }

    static func < (lhs: NthWeek, rhs: NthWeek) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// 通知時刻（時:分）。
struct TimeOfDay: Codable, Equatable, Hashable, Sendable, Comparable {
    var hour: Int
    var minute: Int

    init(hour: Int, minute: Int) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    /// 0時からの経過分。SwiftData には Int ひとつで保存する。
    init(minutesFromMidnight: Int) {
        let clamped = min(max(minutesFromMidnight, 0), 24 * 60 - 1)
        self.init(hour: clamped / 60, minute: clamped % 60)
    }

    var minutesFromMidnight: Int { hour * 60 + minute }

    /// 指定日のこの時刻の Date。
    func date(on day: Date, calendar: Calendar = .current) -> Date? {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: calendar.startOfDay(for: day))
    }

    var label: String { String(format: "%d:%02d", hour, minute) }

    static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool {
        lhs.minutesFromMidnight < rhs.minutesFromMidnight
    }
}
