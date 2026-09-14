import Foundation
import Testing
@testable import WarrantyPocket

/// 保証期限。「お買い上げ日から1年」の数え方がこのアプリの根幹なので境界を固定する。
struct WarrantyTermTests {

    @Test func oneYearEndsTheDayBeforeTheAnniversary() {
        #expect(WarrantyTerm.lastDay(purchaseDate: day(2025, 10, 15), months: 12, calendar: jst) == day(2026, 10, 14))
    }

    @Test func purchaseTimeDoesNotShiftTheLastDay() {
        #expect(WarrantyTerm.lastDay(purchaseDate: at(2025, 10, 15, 23, 50), months: 12, calendar: jst) == day(2026, 10, 14))
    }

    @Test func monthEndPurchaseFollowsCalendarClamping() {
        // 1/31 + 1か月 = 2/28 → 最終日は 2/27。
        #expect(WarrantyTerm.lastDay(purchaseDate: day(2026, 1, 31), months: 1, calendar: jst) == day(2026, 2, 27))
    }

    @Test func leapDayPurchase() {
        // 2024/2/29 + 12か月 = 2025/2/28 → 最終日は 2025/2/27。
        #expect(WarrantyTerm.lastDay(purchaseDate: day(2024, 2, 29), months: 12, calendar: jst) == day(2025, 2, 27))
    }

    @Test func zeroMonthsHasNoWarranty() {
        #expect(WarrantyTerm.lastDay(purchaseDate: day(2025, 1, 1), months: 0, calendar: jst) == nil)
        #expect(WarrantyTerm.periods(purchaseDate: day(2025, 1, 1), warrantyMonths: nil, extendedMonths: nil, calendar: jst).isEmpty)
    }

    @Test func stateBoundaries() throws {
        let period = try #require(
            WarrantyTerm.periods(purchaseDate: day(2025, 10, 15), warrantyMonths: 12, extendedMonths: nil, calendar: jst).first
        )
        // 最終日 2026/10/14
        #expect(WarrantyTerm.status(of: period, now: at(2026, 9, 13, 12), calendar: jst).state == .active)   // 31日前
        #expect(WarrantyTerm.status(of: period, now: at(2026, 9, 14, 12), calendar: jst).state == .soon)     // 30日前
        let lastDay = WarrantyTerm.status(of: period, now: at(2026, 10, 14, 23, 59), calendar: jst)
        #expect(lastDay.state == .soon)
        #expect(lastDay.remainingDays == 0)
        let after = WarrantyTerm.status(of: period, now: at(2026, 10, 15, 0, 1), calendar: jst)
        #expect(after.state == .expired)
        #expect(after.remainingDays == -1)
    }

    @Test func extendedWarrantyKeepsItemCovered() {
        let periods = WarrantyTerm.periods(
            purchaseDate: day(2024, 4, 1), warrantyMonths: 12, extendedMonths: 60, calendar: jst
        )
        #expect(periods.map(\.kind) == [.manufacturer, .extended])
        let overall = WarrantyTerm.overall(periods, now: day(2026, 9, 14), calendar: jst)
        #expect(overall.state == .active)
        #expect(overall.lastDay == day(2029, 3, 31))
    }

    @Test func overallPrefersCoveredOverLaterExpired() {
        // 延長保証（36か月）がメーカー保証（60か月）より先に終わる、ちぐはぐな入力でも「使える保証」を出す。
        let periods = WarrantyTerm.periods(
            purchaseDate: day(2024, 1, 1), warrantyMonths: 60, extendedMonths: 12, calendar: jst
        )
        let overall = WarrantyTerm.overall(periods, now: day(2026, 9, 14), calendar: jst)
        #expect(overall.lastDay == day(2028, 12, 31))
    }

    @Test func overallShowsMostRecentlyExpiredWhenAllEnded() {
        let periods = WarrantyTerm.periods(
            purchaseDate: day(2020, 1, 1), warrantyMonths: 12, extendedMonths: 36, calendar: jst
        )
        let overall = WarrantyTerm.overall(periods, now: day(2026, 9, 14), calendar: jst)
        #expect(overall.state == .expired)
        #expect(overall.lastDay == day(2022, 12, 31))
        #expect(WarrantyTerm.overall([], now: day(2026, 9, 14), calendar: jst) == .none)
    }

    @Test func elapsedFractionIsClamped() throws {
        let period = try #require(
            WarrantyTerm.periods(purchaseDate: day(2026, 1, 1), warrantyMonths: 12, extendedMonths: nil, calendar: jst).first
        )
        #expect(WarrantyTerm.elapsedFraction(of: period, now: day(2025, 6, 1), calendar: jst) == 0)
        #expect(WarrantyTerm.elapsedFraction(of: period, now: day(2027, 6, 1), calendar: jst) == 1)
        let middle = WarrantyTerm.elapsedFraction(of: period, now: day(2026, 7, 2), calendar: jst)
        #expect(middle > 0.49 && middle < 0.51)
    }
}
