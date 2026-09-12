import Foundation
import Testing
@testable import GomiAlarm

/// 月カレンダーの升目。前後の余白の数を間違えると、日付が丸ごと1列ずれて表示される。
/// 2026年9月: 1日(火)始まり・30日。2028年2月: 1日(火)始まり・29日（うるう年）。
struct CalendarMonthTests {

    @Test func leadingBlanksMatchTheFirstWeekday() {
        let month = CalendarMonth.make(containing: day(2026, 9, 10), calendar: jst)
        // 日曜始まりのカレンダーで1日が火曜 → 先頭に2つ余白。
        #expect(month.weeks.first?.prefix(2).allSatisfy { $0 == nil } == true)
        #expect(month.weeks.first?[2] == day(2026, 9, 1))
    }

    @Test func containsEveryDayOfTheMonth() {
        let month = CalendarMonth.make(containing: day(2026, 9, 10), calendar: jst)
        #expect(month.days.count == 30)
        #expect(month.days.first == day(2026, 9, 1))
        #expect(month.days.last == day(2026, 9, 30))
    }

    @Test func weeksAreAlwaysSevenCells() {
        let month = CalendarMonth.make(containing: day(2026, 9, 10), calendar: jst)
        #expect(month.weeks.allSatisfy { $0.count == 7 })
        // 2 + 30 = 32 → 35升（5週）に揃う。
        #expect(month.weeks.count == 5)
    }

    @Test func leapFebruaryIncludesTheTwentyNinth() {
        let month = CalendarMonth.make(containing: day(2028, 2, 15), calendar: jst)
        #expect(month.days.count == 29)
        #expect(month.days.last == day(2028, 2, 29))
    }

    @Test func nonLeapFebruaryStopsAtTwentyEight() {
        let month = CalendarMonth.make(containing: day(2026, 2, 15), calendar: jst)
        #expect(month.days.count == 28)
        #expect(month.days.last == day(2026, 2, 28))
    }

    @Test func movingAcrossYearBoundary() {
        let december = CalendarMonth.make(containing: day(2026, 12, 15), calendar: jst)
        let january = december.adding(months: 1, calendar: jst)
        #expect(january.firstDay == day(2027, 1, 1))
        #expect(january.adding(months: -1, calendar: jst).firstDay == day(2026, 12, 1))
    }

    @Test func weekdayOrderFollowsTheCalendarSetting() {
        #expect(CalendarMonth.weekdayOrder(calendar: jst) == Weekday.allCases)
        var mondayFirst = jst
        mondayFirst.firstWeekday = 2
        #expect(CalendarMonth.weekdayOrder(calendar: mondayFirst).first == .monday)
        #expect(CalendarMonth.weekdayOrder(calendar: mondayFirst).last == .sunday)
    }

    @Test func mondayFirstCalendarShiftsTheBlanks() {
        var mondayFirst = jst
        mondayFirst.firstWeekday = 2
        let month = CalendarMonth.make(containing: day(2026, 9, 10), calendar: mondayFirst)
        // 月曜始まりなら1日(火)の前は1つだけ余白。
        #expect(month.weeks.first?[0] == nil)
        #expect(month.weeks.first?[1] == day(2026, 9, 1))
    }
}

/// オンボーディングのテンプレート。登録ゼロで終わらせないための入口。
struct KindTemplateTests {

    @Test func everyTemplateIsImmediatelySavable() {
        // テンプレから作った種類がそのまま保存できないと、選んだのに登録されない事故になる。
        for template in KindTemplate.all {
            #expect(template.draft.isValid, "\(template.name) が保存条件を満たしていない")
        }
    }

    @Test func defaultSelectionFitsTheFreePlan() {
        // 初回から課金の壁に当てないため、既定のチェックは無料枠ちょうどに収める。
        #expect(KindTemplate.defaultSelection.count == ProLimits.freeKinds)
        #expect(ProLimits.canAddKind(currentCount: KindTemplate.defaultSelection.count - 1, isPro: false))
    }

    @Test func identifiersAreUnique() {
        #expect(Set(KindTemplate.all.map(\.id)).count == KindTemplate.all.count)
    }

    @Test func draftCarriesNameAndRules() {
        let template = KindTemplate.all[1]
        #expect(template.draft.name == template.name)
        #expect(template.draft.specs == template.specs)
        #expect(template.draft.colorHex == template.colorHex)
    }
}
