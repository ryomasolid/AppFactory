import Foundation
import Testing
@testable import GomiAlarm

/// ホームに出す予定の組み立て。
/// 画面の予定と実際に鳴る通知が食い違うと信用を失うので、通知と同じ条件で並ぶことを固定する。
struct UpcomingScheduleTests {

    private let burnable = KindPlan(
        name: "燃えるゴミ", sortOrder: 0,
        specs: [RuleSpec(frequency: .weekly, weekdays: [.monday, .thursday])]
    )
    private let plastic = KindPlan(
        name: "プラ", sortOrder: 1,
        specs: [RuleSpec(frequency: .weekly, weekdays: [.monday])]
    )

    @Test func daysAreSortedAndSkipEmptyDates() {
        let days = UpcomingSchedule.days(
            for: [burnable], from: day(2026, 9, 1), through: day(2026, 9, 14), calendar: jst
        )
        #expect(days.map(\.date) == [day(2026, 9, 3), day(2026, 9, 7), day(2026, 9, 10), day(2026, 9, 14)])
    }

    @Test func kindsOnTheSameDayAreGroupedInDisplayOrder() {
        // 月曜は2種類とも収集。並びは sortOrder のまま（画面の色ドットの順が毎回変わらないように）。
        let days = UpcomingSchedule.days(
            for: [burnable, plastic], from: day(2026, 9, 7), through: day(2026, 9, 7), calendar: jst
        )
        #expect(days.count == 1)
        #expect(days.first?.kindIDs == [burnable.id, plastic.id])
    }

    @Test func holidaysAreSkippedWhenSettingIsOn() {
        var settings = NotificationSettings.default
        settings.skipHolidays = true
        let days = UpcomingSchedule.days(
            for: [burnable], from: day(2026, 9, 14), through: day(2026, 9, 24),
            settings: settings, calendar: jst
        )
        // 月曜は 9/14, 9/21, 9/28、木曜は 9/17, 9/24。
        // このうち 9/21 は敬老の日なので、通知と同じく予定からも消える。
        #expect(days.map(\.date) == [day(2026, 9, 14), day(2026, 9, 17), day(2026, 9, 24)])
    }

    @Test func holidaysRemainWhenSettingIsOff() {
        let days = UpcomingSchedule.days(
            for: [burnable], from: day(2026, 9, 14), through: day(2026, 9, 24), calendar: jst
        )
        #expect(days.map(\.date).contains(day(2026, 9, 21)))
    }

    @Test func reversedRangeIsEmpty() {
        #expect(UpcomingSchedule.days(
            for: [burnable], from: day(2026, 9, 14), through: day(2026, 9, 1), calendar: jst
        ).isEmpty)
    }
}

/// 「出した」の連続回数。
struct StreakCalculatorTests {

    private let kindA = UUID()
    private let kindB = UUID()

    private func days(_ dates: [Date], kinds: [UUID]) -> [CollectionDay] {
        dates.map { CollectionDay(date: $0, kindIDs: kinds) }
    }

    private func done(_ pairs: [(UUID, Date)]) -> Set<StreakCalculator.DoneKey> {
        Set(pairs.map { StreakCalculator.DoneKey(kindID: $0.0, date: $0.1, calendar: jst) })
    }

    @Test func countsConsecutiveDoneDays() {
        let dates = [day(2026, 9, 3), day(2026, 9, 7), day(2026, 9, 10)]
        let streak = StreakCalculator.streak(
            days: days(dates, kinds: [kindA]),
            done: done(dates.map { (kindA, $0) }),
            today: day(2026, 9, 10),
            calendar: jst
        )
        #expect(streak == 3)
    }

    @Test func stopsAtTheFirstMissedDay() {
        let dates = [day(2026, 9, 3), day(2026, 9, 7), day(2026, 9, 10)]
        // 9/7 を出し忘れている → 直近の 9/10 のぶんだけ。
        let streak = StreakCalculator.streak(
            days: days(dates, kinds: [kindA]),
            done: done([(kindA, day(2026, 9, 3)), (kindA, day(2026, 9, 10))]),
            today: day(2026, 9, 10),
            calendar: jst
        )
        #expect(streak == 1)
    }

    @Test func todayDoesNotBreakTheStreakBeforeItIsDone() {
        // 今日ぶんはこれから出すので、未チェックでも連続は途切れない。
        let dates = [day(2026, 9, 3), day(2026, 9, 7), day(2026, 9, 10)]
        let streak = StreakCalculator.streak(
            days: days(dates, kinds: [kindA]),
            done: done([(kindA, day(2026, 9, 3)), (kindA, day(2026, 9, 7))]),
            today: day(2026, 9, 10),
            calendar: jst
        )
        #expect(streak == 2)
    }

    @Test func allKindsOfTheDayMustBeDone() {
        // 同じ日に2種類あるとき、片方だけでは1回にカウントしない。
        let date = day(2026, 9, 7)
        let streak = StreakCalculator.streak(
            days: days([date], kinds: [kindA, kindB]),
            done: done([(kindA, date)]),
            today: day(2026, 9, 8),
            calendar: jst
        )
        #expect(streak == 0)
    }

    @Test func futureDaysAreIgnored() {
        let streak = StreakCalculator.streak(
            days: days([day(2026, 9, 17)], kinds: [kindA]),
            done: done([(kindA, day(2026, 9, 17))]),
            today: day(2026, 9, 10),
            calendar: jst
        )
        #expect(streak == 0)
    }
}

/// 色文字列の解釈。SwiftData に入る値なので、壊れていても落ちないこと。
struct ThemeColorTests {

    @Test func parsesHexWithAndWithoutHash() {
        let a = Theme.rgb(fromHex: "#E8543F")
        let b = Theme.rgb(fromHex: "E8543F")
        #expect(a?.red == 232.0 / 255)
        #expect(a?.green == 84.0 / 255)
        #expect(a?.blue == 63.0 / 255)
        #expect(b?.red == a?.red)
    }

    @Test func rejectsBrokenValues() {
        #expect(Theme.rgb(fromHex: "") == nil)
        #expect(Theme.rgb(fromHex: "#ZZZZZZ") == nil)
        #expect(Theme.rgb(fromHex: "#FFF") == nil)
        #expect(Theme.rgb(fromHex: "#E8543F00") == nil)
    }
}
