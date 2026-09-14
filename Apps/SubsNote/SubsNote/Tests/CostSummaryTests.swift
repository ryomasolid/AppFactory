import Foundation
import Testing
@testable import SubsNote

/// 金額の換算と集計。丸め方と「今月の支払い」をカレンダーと一致させる。
struct CostSummaryTests {
    let today = at(2026, 9, 14, 12)

    @Test func conversionPerCycle() {
        #expect(CostSummary.monthly(billing(day(2026, 1, 1), .week, price: 300)) == 1300)
        #expect(CostSummary.monthly(billing(day(2026, 1, 1), .year, price: 5900)) == 492)
        #expect(CostSummary.monthly(billing(day(2026, 1, 1), .month, price: 3000, interval: 3)) == 1000)
        #expect(CostSummary.yearly(billing(day(2026, 1, 1), .month, price: 1590)).rounded() == 19080)
    }

    @Test func totalsMonthlyYearlyDaily() {
        // 年あたり 19,080 + 5,900 + 15,600 = 40,580 → 月 3,381.67 / 1日 111.18
        let totals = CostSummary.totals([
            billing(day(2026, 1, 1), .month, price: 1590),
            billing(day(2026, 1, 1), .year, price: 5900),
            billing(day(2026, 1, 1), .week, price: 300),
        ])
        #expect(totals == CostTotals(monthly: 3382, yearly: 40580, daily: 111))
    }

    @Test func sumBeforeRounding() {
        // ¥1,000 を3か月ごと ×3件: 1件ずつ丸めると 333×3 = 999、分数のまま足すと 1,000。
        let plans = Array(repeating: billing(day(2026, 1, 1), price: 1000, interval: 3), count: 3)
        #expect(plans.map(CostSummary.monthly).reduce(0, +) == 999)
        #expect(CostSummary.totals(plans).monthly == 1000)
    }

    @Test func trialsAndCancelledAreExcludedFromTotals() {
        let plans = [
            billing(day(2026, 8, 20), price: 1590),
            billing(day(2026, 9, 21), price: 990, trialEnd: day(2026, 9, 20)),
            billing(day(2026, 1, 5), price: 980, cancelledAt: day(2026, 8, 1)),
        ]
        #expect(CostSummary.activeTotals(plans, today: today, calendar: jst).monthly == 1590)
        #expect(CostSummary.trialMonthlyAddition(plans, today: today, calendar: jst) == 990)
        #expect(CostSummary.yearlySaved(plans) == 11760)
    }

    @Test func paymentsInMonthUseActualAmounts() {
        let plans = [
            billing(day(2026, 8, 20), price: 1590),                 // 9/20
            billing(day(2025, 9, 1), .year, price: 5900),           // 9/1
            billing(day(2026, 9, 1), .week, price: 300),            // 9/1, 8, 15, 22, 29
            billing(day(2026, 9, 21), price: 990, trialEnd: day(2026, 9, 20)), // 体験後の初回 9/21
            billing(day(2026, 1, 5), price: 980, cancelledAt: day(2026, 8, 1)),
        ]
        #expect(CostSummary.paymentsInMonth(plans, containing: today, calendar: jst) == 1590 + 5900 + 1500 + 990)
        // 9/14 以降: 9/15・22・29 の週払い、9/20、9/21。
        #expect(CostSummary.remainingInMonth(plans, today: today, calendar: jst) == 900 + 1590 + 990)
    }

    @Test func monthRange() {
        let range = CostSummary.monthRange(containing: at(2028, 2, 10, 15), calendar: jst)
        #expect(range.start == day(2028, 2, 1))
        #expect(range.end == day(2028, 2, 29))
    }

    @Test func breakdownSortedByAmount() {
        let entries = CostSummary.breakdown([
            (key: SubCategory.music, plan: billing(day(2026, 1, 1), price: 1080)),
            (key: SubCategory.video, plan: billing(day(2026, 1, 1), price: 1590)),
            (key: SubCategory.video, plan: billing(day(2026, 1, 1), price: 550)),
            (key: SubCategory.cloud, plan: billing(day(2026, 1, 1), .year, price: 12960)),
        ])
        #expect(entries.map(\.key) == [.video, .music, .cloud])
        #expect(entries.map(\.monthly) == [2140, 1080, 1080])
        #expect(entries.first?.count == 2)
    }
}
