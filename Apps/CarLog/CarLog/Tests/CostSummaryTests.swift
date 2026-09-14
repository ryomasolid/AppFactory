import Foundation
import Testing
@testable import CarLog

/// コスト集計。
struct CostSummaryTests {

    private func expense(_ date: Date, _ category: ExpenseCategory, _ amount: Int) -> ExpenseEntry {
        ExpenseEntry(id: UUID(), date: date, category: category, amount: amount)
    }

    @Test func fuelIsMergedAsGasolineCategory() {
        let breakdown = CostSummary.breakdown(
            fuel: [
                fuel(day(2026, 3, 1), odometer: 1000, liters: 30, price: 5000),
                fuel(day(2026, 3, 20), odometer: 1600, liters: 30, price: 5200),
            ],
            expenses: [expense(day(2026, 3, 5), .parking, 11000), expense(day(2026, 3, 6), .wash, 1200)],
            in: DateInterval(start: day(2026, 3, 1), end: day(2026, 3, 31)),
            calendar: jst
        )
        #expect(breakdown.total == 22400)
        #expect(breakdown.categories.map(\.category) == [.parking, .fuel, .wash])
        #expect(breakdown.categories.first { $0.category == .fuel }?.amount == 10200)
    }

    @Test func costPerKilometerUsesDistanceWithinThePeriod() {
        let breakdown = CostSummary.breakdown(
            fuel: [
                fuel(day(2026, 3, 1), odometer: 1000, liters: 30, price: 6000),
                fuel(day(2026, 3, 20), odometer: 1600, liters: 30, price: 6000),
            ],
            expenses: [],
            in: DateInterval(start: day(2026, 3, 1), end: day(2026, 3, 31)),
            calendar: jst
        )
        #expect(breakdown.distance == 600)
        #expect(breakdown.costPerKilometer == 20)
    }

    @Test func noCostPerKilometerWithoutDistance() {
        let breakdown = CostSummary.breakdown(
            fuel: [fuel(day(2026, 3, 1), odometer: 1000, liters: 30, price: 6000)],
            expenses: [],
            in: DateInterval(start: day(2026, 3, 1), end: day(2026, 3, 31)),
            calendar: jst
        )
        #expect(breakdown.costPerKilometer == nil)
    }

    @Test func boundaryDaysAreIncludedRegardlessOfTime() {
        let breakdown = CostSummary.breakdown(
            fuel: [],
            expenses: [expense(at(2026, 3, 31, 23, 30), .toll, 900), expense(at(2026, 4, 1, 0, 10), .toll, 500)],
            in: DateInterval(start: day(2026, 3, 1), end: day(2026, 3, 31)),
            calendar: jst
        )
        #expect(breakdown.total == 900)
    }

    @Test func monthlyAverageDividesByMonthsInThePeriod() {
        let breakdown = CostSummary.breakdown(
            fuel: [],
            expenses: [expense(day(2026, 1, 10), .tax, 36000)],
            in: DateInterval(start: day(2026, 1, 1), end: day(2026, 6, 15)),
            calendar: jst
        )
        #expect(breakdown.months == 6)
        #expect(breakdown.monthlyAverage == 6000)
    }

    @Test func monthlyTotalsFillEmptyMonthsWithZero() {
        let totals = CostSummary.monthlyTotals(
            fuel: [fuel(day(2026, 1, 5), odometer: 0, liters: 30, price: 5000)],
            expenses: [expense(day(2026, 3, 1), .parking, 11000)],
            in: DateInterval(start: day(2026, 1, 1), end: day(2026, 3, 31)),
            calendar: jst
        )
        #expect(totals.map(\.amount) == [5000, 0, 11000])
        #expect(totals.map(\.month) == [day(2026, 1, 1), day(2026, 2, 1), day(2026, 3, 1)])
    }

    @Test func periodIntervals() {
        let now = at(2026, 6, 15, 10)
        #expect(CostPeriod.month.interval(now: now, calendar: jst).start == day(2026, 6, 1))
        #expect(CostPeriod.year.interval(now: now, calendar: jst).start == day(2026, 1, 1))
        #expect(CostPeriod.all.interval(now: now, earliest: day(2024, 2, 3), calendar: jst).start == day(2024, 2, 3))
        // 記録が無ければ今日1日。
        #expect(CostPeriod.all.interval(now: now, calendar: jst).start == day(2026, 6, 15))
    }
}
