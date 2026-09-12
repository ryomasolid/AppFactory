import Foundation
import Testing
@testable import GomiAlarm

/// 祝日の計算。祝日スキップ設定がオンのときだけ使うが、ずれると収集日を1日まるごと落とすので検証する。
struct HolidayCalendarTests {

    @Test func fixedAndHappyMondayHolidays() {
        #expect(HolidayCalendar.isHoliday(day(2026, 1, 1), calendar: jst))      // 元日
        #expect(HolidayCalendar.isHoliday(day(2026, 1, 12), calendar: jst))     // 成人の日（1月第2月曜）
        #expect(HolidayCalendar.isHoliday(day(2026, 10, 12), calendar: jst))    // スポーツの日（10月第2月曜）
        #expect(HolidayCalendar.isHoliday(day(2026, 11, 23), calendar: jst))    // 勤労感謝の日
    }

    @Test func equinoxHolidays() {
        #expect(HolidayCalendar.isHoliday(day(2026, 3, 20), calendar: jst))     // 春分の日
        #expect(HolidayCalendar.isHoliday(day(2026, 9, 23), calendar: jst))     // 秋分の日
        #expect(HolidayCalendar.isHoliday(day(2027, 3, 21), calendar: jst))     // 2027年の春分は3/21
        #expect(!HolidayCalendar.isHoliday(day(2027, 3, 20), calendar: jst))
    }

    @Test func substituteHolidayAfterSunday() {
        // 2026年は 5/3(日) 憲法記念日 → 5/4, 5/5 も祝日なので 5/6(水) が振替休日。
        #expect(HolidayCalendar.isHoliday(day(2026, 5, 6), calendar: jst))
    }

    @Test func nationalHolidaySandwichedBetweenTwo() {
        // 2026年は 9/21(月) 敬老の日、9/23(水) 秋分 → 挟まれた 9/22(火) が国民の休日。
        #expect(HolidayCalendar.isHoliday(day(2026, 9, 21), calendar: jst))
        #expect(HolidayCalendar.isHoliday(day(2026, 9, 22), calendar: jst))
        #expect(HolidayCalendar.isHoliday(day(2026, 9, 23), calendar: jst))
    }

    @Test func plainWeekdayIsNotHoliday() {
        #expect(!HolidayCalendar.isHoliday(day(2026, 9, 24), calendar: jst))
        #expect(!HolidayCalendar.isHoliday(day(2026, 6, 15), calendar: jst))    // 6月は祝日なし
    }

    @Test func rangeQuerySpansYears() {
        let holidays = HolidayCalendar.holidays(
            from: day(2026, 12, 25), through: day(2027, 1, 15), calendar: jst
        )
        #expect(holidays.contains(day(2027, 1, 1)))
        #expect(holidays.contains(day(2027, 1, 11)))   // 2027年の成人の日
        #expect(!holidays.contains(day(2026, 12, 25)))
    }
}
