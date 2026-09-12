import Foundation

/// 収集の周期。
enum RuleFrequency: String, Codable, CaseIterable, Identifiable, Sendable {
    case weekly       // 毎週 月・木
    case biweekly     // 隔週（基準日の週と同じ偶奇の週）
    case nthWeekday   // 第2・第4 水曜 / 最終 金曜
    case monthlyDay   // 毎月15日
    case once         // 単発（粗大ごみの予約日など）

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weekly: return String(localized: "毎週")
        case .biweekly: return String(localized: "隔週")
        case .nthWeekday: return String(localized: "第n曜日")
        case .monthlyDay: return String(localized: "毎月◯日")
        case .once: return String(localized: "単発")
        }
    }
}

/// 収集ルールの値型。SwiftData モデル（`CollectionRule`）から切り離してあるので、
/// 日付の列挙ロジック（`ScheduleCalculator`）を永続化なしで単体テストできる。
struct RuleSpec: Codable, Equatable, Hashable, Sendable {
    var frequency: RuleFrequency
    /// weekly / biweekly / nthWeekday で使う曜日。
    var weekdays: Set<Weekday>
    /// nthWeekday で使う「第n」。
    var nthWeeks: Set<NthWeek>
    /// monthlyDay で使う日（1...31）。その月に無い日は月末に丸める。
    var dayOfMonth: Int?
    /// biweekly の基準日（この週と同じ偶奇の週が収集週）／ once の収集日。
    var anchorDate: Date?

    init(
        frequency: RuleFrequency,
        weekdays: Set<Weekday> = [],
        nthWeeks: Set<NthWeek> = [],
        dayOfMonth: Int? = nil,
        anchorDate: Date? = nil
    ) {
        self.frequency = frequency
        self.weekdays = weekdays
        self.nthWeeks = nthWeeks
        self.dayOfMonth = dayOfMonth
        self.anchorDate = anchorDate
    }

    /// 設定として成立しているか（曜日未選択のルールなどを弾く）。
    var isValid: Bool {
        switch frequency {
        case .weekly: return !weekdays.isEmpty
        case .biweekly: return !weekdays.isEmpty && anchorDate != nil
        case .nthWeekday: return !weekdays.isEmpty && !nthWeeks.isEmpty
        case .monthlyDay: return (dayOfMonth ?? 0) >= 1 && (dayOfMonth ?? 0) <= 31
        case .once: return anchorDate != nil
        }
    }

    /// 「毎週 月・木」「第2・第4 水曜」のような要約（一覧カードに出す）。
    var summary: String {
        let days = weekdays.sorted().map(\.shortLabel).joined(separator: "・")
        switch frequency {
        case .weekly:
            return String(localized: "毎週 \(days)")
        case .biweekly:
            return String(localized: "隔週 \(days)")
        case .nthWeekday:
            let nth = nthWeeks.sorted().map(\.label).joined(separator: "・")
            return String(localized: "\(nth) \(days)曜")
        case .monthlyDay:
            return String(localized: "毎月\(dayOfMonth ?? 1)日")
        case .once:
            guard let anchorDate else { return String(localized: "単発") }
            return anchorDate.formatted(.dateTime.month().day().locale(Locale(identifier: "ja_JP")))
        }
    }
}
