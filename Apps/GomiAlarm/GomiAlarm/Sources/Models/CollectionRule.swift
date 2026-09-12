import Foundation
import SwiftData

/// 収集ルールの永続化モデル。
/// 実体は `RuleSpec`（値型）で、ここは SwiftData に保存できる素の型へ分解して持つだけ。
/// Set や enum を直接プロパティにすると SwiftData のスキーマ移行で詰まりやすいので、
/// あえて String / [Int] / Int? に落としている。
@Model
final class CollectionRule {
    var frequencyRaw: String = RuleFrequency.weekly.rawValue
    var weekdayValues: [Int] = []
    var nthWeekValues: [Int] = []
    var dayOfMonth: Int?
    var anchorDate: Date?
    var kind: GarbageKind?

    init(spec: RuleSpec) {
        self.frequencyRaw = spec.frequency.rawValue
        self.weekdayValues = spec.weekdays.map(\.rawValue).sorted()
        self.nthWeekValues = spec.nthWeeks.map(\.rawValue).sorted()
        self.dayOfMonth = spec.dayOfMonth
        self.anchorDate = spec.anchorDate
    }

    var spec: RuleSpec {
        get {
            RuleSpec(
                frequency: RuleFrequency(rawValue: frequencyRaw) ?? .weekly,
                weekdays: Set(weekdayValues.compactMap(Weekday.init(rawValue:))),
                nthWeeks: Set(nthWeekValues.compactMap(NthWeek.init(rawValue:))),
                dayOfMonth: dayOfMonth,
                anchorDate: anchorDate
            )
        }
        set {
            frequencyRaw = newValue.frequency.rawValue
            weekdayValues = newValue.weekdays.map(\.rawValue).sorted()
            nthWeekValues = newValue.nthWeeks.map(\.rawValue).sorted()
            dayOfMonth = newValue.dayOfMonth
            anchorDate = newValue.anchorDate
        }
    }
}
