import Foundation
import Testing
@testable import GomiAlarm

/// 周期エディタのプリセット。
/// 編集で開き直したときに入口が復元されないと、ユーザーは「設定が消えた」と受け取るので往復を固定する。
struct RulePresetTests {

    @Test func secondFourthBuildsNthWeekdayRule() {
        // 「第2・第4」を押して「水」を押すだけで、第2・第4水曜のルールになる。
        let spec = RulePreset.secondFourth.spec(
            weekdays: [.wednesday], anchorDate: day(2026, 9, 1), calendar: jst
        )
        #expect(spec == RuleSpec(
            frequency: .nthWeekday, weekdays: [.wednesday], nthWeeks: [.second, .fourth]
        ))
    }

    @Test func biweeklyDerivesWeekdayFromTheChosenDate() {
        // 隔週は「次の収集日」を選ぶだけで、曜日も基準週も決まる。9/1 は火曜。
        let spec = RulePreset.biweekly.spec(
            weekdays: [], anchorDate: day(2026, 9, 1), calendar: jst
        )
        #expect(spec?.frequency == .biweekly)
        #expect(spec?.weekdays == [.tuesday])
        #expect(spec?.anchorDate == day(2026, 9, 1))
    }

    @Test func customBuildsNothingByItself() {
        // 「詳細」は専用UIで直接組むので、プリセットからは作らない。
        #expect(RulePreset.custom.spec(weekdays: [.monday], anchorDate: day(2026, 9, 1)) == nil)
    }

    @Test func presetIsRestoredFromExistingRule() {
        #expect(RulePreset.preset(for: RuleSpec(frequency: .weekly, weekdays: [.monday])) == .weekly)
        #expect(RulePreset.preset(for: RuleSpec(
            frequency: .nthWeekday, weekdays: [.wednesday], nthWeeks: [.second, .fourth]
        )) == .secondFourth)
        #expect(RulePreset.preset(for: RuleSpec(
            frequency: .nthWeekday, weekdays: [.wednesday], nthWeeks: [.first, .third]
        )) == .firstThird)
    }

    @Test func unrepresentableRulesFallBackToCustom() {
        // プリセットで表現できない組み合わせは「詳細」に落とす（設定を壊さないため）。
        #expect(RulePreset.preset(for: RuleSpec(
            frequency: .nthWeekday, weekdays: [.wednesday], nthWeeks: [.second]
        )) == .custom)
        #expect(RulePreset.preset(for: RuleSpec(
            frequency: .nthWeekday, weekdays: [.friday], nthWeeks: [.last]
        )) == .custom)
        #expect(RulePreset.preset(for: RuleSpec(frequency: .monthlyDay, dayOfMonth: 15)) == .custom)
        #expect(RulePreset.preset(for: RuleSpec(frequency: .once, anchorDate: day(2026, 10, 3))) == .custom)
        // 隔週プリセットは曜日1つぶんしか表現できない。
        #expect(RulePreset.preset(for: RuleSpec(
            frequency: .biweekly, weekdays: [.tuesday, .friday], anchorDate: day(2026, 9, 1)
        )) == .custom)
    }

    @Test func presetRoundTripsThroughSpec() {
        // プリセット → ルール → プリセット で戻ってくること。
        for preset in RulePreset.allCases where preset != .custom {
            let spec = preset.spec(weekdays: [.wednesday], anchorDate: day(2026, 9, 2), calendar: jst)
            #expect(spec != nil)
            #expect(RulePreset.preset(for: spec!) == preset)
        }
    }

    @Test func weekdayChipsAreHiddenForBiweekly() {
        // 隔週は日付から曜日を決めるので、曜日チップを出すと二重入力になる。
        #expect(RulePreset.weekly.usesWeekdayChips)
        #expect(RulePreset.secondFourth.usesWeekdayChips)
        #expect(!RulePreset.biweekly.usesWeekdayChips)
        #expect(!RulePreset.custom.usesWeekdayChips)
    }
}
