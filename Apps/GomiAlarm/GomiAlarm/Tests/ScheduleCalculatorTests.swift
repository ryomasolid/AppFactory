import Foundation
import Testing
@testable import GomiAlarm

/// 収集日の列挙。ここがずれると通知が全部ずれるので、周期ごとに実カレンダーで検証する。
/// 2026年9月: 1日(火)始まり。月=7,14,21,28／水=2,9,16,23,30／木=3,10,17,24／金=4,11,18,25
struct ScheduleCalculatorTests {

    @Test func weeklyPicksEveryMatchingWeekday() {
        let spec = RuleSpec(frequency: .weekly, weekdays: [.monday, .thursday])
        let dates = ScheduleCalculator.occurrences(
            of: spec, from: day(2026, 9, 1), through: day(2026, 9, 14), calendar: jst
        )
        #expect(dates == [day(2026, 9, 3), day(2026, 9, 7), day(2026, 9, 10), day(2026, 9, 14)])
    }

    @Test func nthWeekdayPicksSecondAndFourth() {
        // 「第2・第4 水曜」= 9/9 と 9/23。第5水曜の 9/30 は含まない。
        let spec = RuleSpec(frequency: .nthWeekday, weekdays: [.wednesday], nthWeeks: [.second, .fourth])
        let dates = ScheduleCalculator.occurrences(
            of: spec, from: day(2026, 9, 1), through: day(2026, 9, 30), calendar: jst
        )
        #expect(dates == [day(2026, 9, 9), day(2026, 9, 23)])
    }

    @Test func lastWeekdayPicksFinalOccurrence() {
        // 2026年9月の最終金曜は 9/25（金は 4,11,18,25 の4本）。
        let spec = RuleSpec(frequency: .nthWeekday, weekdays: [.friday], nthWeeks: [.last])
        let dates = ScheduleCalculator.occurrences(
            of: spec, from: day(2026, 9, 1), through: day(2026, 9, 30), calendar: jst
        )
        #expect(dates == [day(2026, 9, 25)])
    }

    @Test func lastWeekdayHandlesFiveWeekMonth() {
        // 水曜が5本ある月（2,9,16,23,30）の最終水曜は 9/30。
        let spec = RuleSpec(frequency: .nthWeekday, weekdays: [.wednesday], nthWeeks: [.last])
        let dates = ScheduleCalculator.occurrences(
            of: spec, from: day(2026, 9, 1), through: day(2026, 9, 30), calendar: jst
        )
        #expect(dates == [day(2026, 9, 30)])
    }

    @Test func fourthAndLastCanBeTheSameDay() {
        // 木曜は4本（3,10,17,24）なので第4木曜＝最終木曜。両方指定しても重複しない。
        let spec = RuleSpec(frequency: .nthWeekday, weekdays: [.thursday], nthWeeks: [.fourth, .last])
        let dates = ScheduleCalculator.occurrences(
            of: spec, from: day(2026, 9, 1), through: day(2026, 9, 30), calendar: jst
        )
        #expect(dates == [day(2026, 9, 24)])
    }

    @Test func biweeklyKeepsWeekParityFromAnchor() {
        // 基準日 9/1(火) の週と同じ偶奇の週だけ。火曜は 1,8,15,22,29 → 1週おきに 1,15,29。
        let spec = RuleSpec(frequency: .biweekly, weekdays: [.tuesday], anchorDate: day(2026, 9, 1))
        let dates = ScheduleCalculator.occurrences(
            of: spec, from: day(2026, 9, 1), through: day(2026, 9, 30), calendar: jst
        )
        #expect(dates == [day(2026, 9, 1), day(2026, 9, 15), day(2026, 9, 29)])
    }

    @Test func biweeklyWorksBeforeAnchorDate() {
        // 基準日より前でも偶奇は保たれる（8/18 は基準日の2週前）。
        let spec = RuleSpec(frequency: .biweekly, weekdays: [.tuesday], anchorDate: day(2026, 9, 1))
        let dates = ScheduleCalculator.occurrences(
            of: spec, from: day(2026, 8, 10), through: day(2026, 8, 31), calendar: jst
        )
        #expect(dates == [day(2026, 8, 18)])
    }

    @Test func monthlyDayClampsToEndOfShortMonth() {
        // 「毎月31日」は2月では月末に丸める（2026年2月は28日まで）。
        let spec = RuleSpec(frequency: .monthlyDay, dayOfMonth: 31)
        let dates = ScheduleCalculator.occurrences(
            of: spec, from: day(2026, 1, 1), through: day(2026, 4, 30), calendar: jst
        )
        #expect(dates == [day(2026, 1, 31), day(2026, 2, 28), day(2026, 3, 31), day(2026, 4, 30)])
    }

    @Test func monthlyDayClampsToLeapDay() {
        // うるう年の2月は29日に丸める。
        let spec = RuleSpec(frequency: .monthlyDay, dayOfMonth: 30)
        let dates = ScheduleCalculator.occurrences(
            of: spec, from: day(2028, 2, 1), through: day(2028, 2, 29), calendar: jst
        )
        #expect(dates == [day(2028, 2, 29)])
    }

    @Test func onceMatchesOnlyThatDay() {
        let spec = RuleSpec(frequency: .once, anchorDate: day(2026, 10, 3))
        let dates = ScheduleCalculator.occurrences(
            of: spec, from: day(2026, 9, 1), through: day(2026, 12, 31), calendar: jst
        )
        #expect(dates == [day(2026, 10, 3)])
    }

    @Test func multipleRulesAreMergedAndDeduplicated() {
        // 毎週水曜 と 第2・第4水曜 を両方持つ種類 → 水曜が重複しない。
        let specs = [
            RuleSpec(frequency: .weekly, weekdays: [.wednesday]),
            RuleSpec(frequency: .nthWeekday, weekdays: [.wednesday], nthWeeks: [.second, .fourth]),
        ]
        let dates = ScheduleCalculator.occurrences(
            of: specs, from: day(2026, 9, 1), through: day(2026, 9, 30), calendar: jst
        )
        #expect(dates == [day(2026, 9, 2), day(2026, 9, 9), day(2026, 9, 16), day(2026, 9, 23), day(2026, 9, 30)])
    }

    @Test func invalidRulesProduceNothing() {
        // 曜日未選択・基準日なしなど、設定途中のルールは無視する。
        #expect(ScheduleCalculator.occurrences(
            of: RuleSpec(frequency: .weekly), from: day(2026, 9, 1), through: day(2026, 9, 30), calendar: jst
        ).isEmpty)
        #expect(ScheduleCalculator.occurrences(
            of: RuleSpec(frequency: .biweekly, weekdays: [.tuesday]),
            from: day(2026, 9, 1), through: day(2026, 9, 30), calendar: jst
        ).isEmpty)
    }

    @Test func reversedRangeIsEmpty() {
        let spec = RuleSpec(frequency: .weekly, weekdays: [.monday])
        #expect(ScheduleCalculator.occurrences(
            of: spec, from: day(2026, 9, 30), through: day(2026, 9, 1), calendar: jst
        ).isEmpty)
    }
}
