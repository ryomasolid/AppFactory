import Foundation

/// 周期エディタの入口に並べるプリセット。
///
/// ゴミ出しで実際に使われる周期はほぼ「毎週」「隔週」「第1・第3」「第2・第4」に収まる。
/// 周期の種類 → 第n → 曜日 と3段階で選ばせると確実に離脱するので、
/// **「第2・第4」を押して「水」を押すだけ**で作れる入口を用意し、残りを `custom` に押し込める。
enum RulePreset: String, CaseIterable, Identifiable, Sendable {
    case weekly
    case biweekly
    case firstThird
    case secondFourth
    case custom

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weekly: return String(localized: "毎週")
        case .biweekly: return String(localized: "隔週")
        case .firstThird: return String(localized: "第1・第3")
        case .secondFourth: return String(localized: "第2・第4")
        case .custom: return String(localized: "詳細")
        }
    }

    /// このプリセットが固定で使う「第n」。
    var nthWeeks: Set<NthWeek> {
        switch self {
        case .firstThird: return [.first, .third]
        case .secondFourth: return [.second, .fourth]
        default: return []
        }
    }

    /// 曜日チップを出すか。隔週は「次の収集日」の日付から曜日を決めるので出さない。
    var usesWeekdayChips: Bool {
        switch self {
        case .weekly, .firstThird, .secondFourth: return true
        case .biweekly, .custom: return false
        }
    }

    /// プリセットからルールを組む。`custom` は詳細UIで直接組むので nil。
    ///
    /// 隔週は「次の収集日」を1つ選べば曜日も基準週も決まるので、その日付から両方を導く。
    func spec(weekdays: Set<Weekday>, anchorDate: Date, calendar: Calendar = .current) -> RuleSpec? {
        switch self {
        case .weekly:
            return RuleSpec(frequency: .weekly, weekdays: weekdays)
        case .biweekly:
            let day = calendar.startOfDay(for: anchorDate)
            return RuleSpec(
                frequency: .biweekly,
                weekdays: [Weekday.of(day, calendar: calendar)],
                anchorDate: day
            )
        case .firstThird, .secondFourth:
            return RuleSpec(frequency: .nthWeekday, weekdays: weekdays, nthWeeks: nthWeeks)
        case .custom:
            return nil
        }
    }

    /// 既存のルールがどのプリセットに当たるか（編集時に入口を復元するため）。
    /// プリセットで表現しきれないものは `custom` に落とす。
    static func preset(for spec: RuleSpec) -> RulePreset {
        switch spec.frequency {
        case .weekly:
            return .weekly
        case .biweekly:
            // 隔週プリセットは曜日1つぶんしか表現できない。
            return spec.weekdays.count == 1 ? .biweekly : .custom
        case .nthWeekday:
            if spec.nthWeeks == [.first, .third] { return .firstThird }
            if spec.nthWeeks == [.second, .fourth] { return .secondFourth }
            return .custom
        case .monthlyDay, .once:
            return .custom
        }
    }
}
