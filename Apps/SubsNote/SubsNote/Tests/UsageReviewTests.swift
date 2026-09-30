import Foundation
import Testing
@testable import SubsNote

/// 見直し。1回あたりの値段と、やめる候補の選び方。
struct UsageReviewTests {
    @Test func perUseRoundsHalfUp() {
        #expect(UsageReview.perUse(monthly: 3278, uses: 2) == 1639)
        #expect(UsageReview.perUse(monthly: 1000, uses: 3) == 333)
        #expect(UsageReview.perUse(monthly: 1001, uses: 2) == 501)
        #expect(UsageReview.perUse(monthly: 1590, uses: 0) == nil)
    }

    @Test func verdictThresholds() {
        #expect(UsageReview.verdict(monthly: 1590, uses: nil) == .unrated)
        #expect(UsageReview.verdict(monthly: 1590, uses: 0) == .unused)
        // ちょうど ¥500 は割高に入れる。
        #expect(UsageReview.verdict(monthly: 1000, uses: 2) == .pricy(perUse: 500))
        #expect(UsageReview.verdict(monthly: 1590, uses: 14) == .worth(perUse: 114))
    }

    @Test func candidatesOnlyUnusedAndPricy() {
        #expect(UsageReview.Verdict.unused.isCandidate)
        #expect(UsageReview.Verdict.pricy(perUse: 800).isCandidate)
        #expect(!UsageReview.Verdict.worth(perUse: 100).isCandidate)
        #expect(!UsageReview.Verdict.unrated.isCandidate)
    }

    @Test func yearlySavingSumsCandidates() {
        let items: [(plan: BillingPlan, uses: Int?)] = [
            (billing(day(2026, 1, 1), price: 1980), 0),  // 使っていない → 年 23,760
            (billing(day(2026, 1, 1), price: 3278), 2),  // 1回 ¥1,639 → 年 39,336
            (billing(day(2026, 1, 1), price: 1590), 14),  // 元が取れている
            (billing(day(2026, 1, 1), price: 990), nil),  // 未記入は数えない
        ]
        #expect(UsageReview.yearlySaving(items) == 63096)
    }

    @Test func yearlyPlanUsesMonthlyEquivalent() {
        // 年 ¥5,400 → 月 ¥450。1回使えば ¥450 で割高ではない。
        let plan = billing(day(2026, 1, 1), .year, price: 5400)
        #expect(UsageReview.verdict(monthly: CostSummary.monthly(plan), uses: 1) == .worth(perUse: 450))
    }

    @Test func staleAfterThirtyDays() {
        let today = at(2026, 9, 30, 12)
        #expect(!UsageReview.isStale(checkedAt: nil, today: today, calendar: jst))
        #expect(!UsageReview.isStale(checkedAt: at(2026, 9, 1, 23), today: today, calendar: jst))
        #expect(UsageReview.isStale(checkedAt: at(2026, 8, 31, 8), today: today, calendar: jst))
    }
}
