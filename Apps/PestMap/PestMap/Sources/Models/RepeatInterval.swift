import Foundation

/// 対策の繰り返し周期。「完了」時に次回予定を自動算出するのに使う。
enum RepeatInterval: String, CaseIterable, Identifiable {
    case none
    case monthly
    case every3Months
    case every6Months
    case yearly

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return String(localized: "繰り返さない")
        case .monthly: return String(localized: "毎月")
        case .every3Months: return String(localized: "3ヶ月ごと")
        case .every6Months: return String(localized: "半年ごと")
        case .yearly: return String(localized: "毎年")
        }
    }

    /// 周期の月数。none は nil。
    var months: Int? {
        switch self {
        case .none: return nil
        case .monthly: return 1
        case .every3Months: return 3
        case .every6Months: return 6
        case .yearly: return 12
        }
    }

    /// 指定日からの次回予定日。none なら nil。
    func nextDate(from date: Date) -> Date? {
        guard let months else { return nil }
        return Calendar.current.date(byAdding: .month, value: months, to: date)
    }
}
