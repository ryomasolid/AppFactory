import Foundation
import Testing
@testable import SubsNote

/// 支払日。起点から数える方式を、月末・閏年・間隔・体験終了で固定する。
struct BillingScheduleTests {

    private func dates(_ plan: BillingPlan, _ range: ClosedRange<Int>) -> [Date] {
        range.compactMap { BillingSchedule.billingDate($0, of: plan, calendar: jst) }
    }

    @Test func monthEndCountsFromAnchor() {
        // 前回に足していくと 3/28 になる。起点から数えるので 3/31 に戻る。
        #expect(dates(billing(day(2026, 1, 31)), 0...3) == [day(2026, 1, 31), day(2026, 2, 28), day(2026, 3, 31), day(2026, 4, 30)])
    }

    @Test func may31() {
        #expect(dates(billing(day(2026, 5, 31)), 1...4) == [day(2026, 6, 30), day(2026, 7, 31), day(2026, 8, 31), day(2026, 9, 30)])
    }

    @Test func leapDayYearly() {
        #expect(dates(billing(day(2024, 2, 29), .year), 1...4) == [day(2025, 2, 28), day(2026, 2, 28), day(2027, 2, 28), day(2028, 2, 29)])
    }

    @Test func nextBillingIsTodayOnBillingDay() {
        let plan = billing(day(2026, 1, 14))
        #expect(BillingSchedule.nextBillingDate(onOrAfter: at(2026, 9, 14, 23), plan: plan, calendar: jst) == day(2026, 9, 14))
        #expect(BillingSchedule.nextBillingDate(onOrAfter: at(2026, 9, 15, 0), plan: plan, calendar: jst) == day(2026, 10, 14))
        // 起点より前なら起点。
        #expect(BillingSchedule.nextBillingDate(onOrAfter: day(2025, 12, 1), plan: plan, calendar: jst) == day(2026, 1, 14))
    }

    @Test func intervalAndWeekly() {
        #expect(BillingSchedule.nextBillingDate(onOrAfter: day(2026, 9, 14), plan: billing(day(2026, 1, 10), interval: 3), calendar: jst) == day(2026, 10, 10))
        // 2026/9/2 は水曜。9/2 → 9/9 → 9/16。
        #expect(BillingSchedule.nextBillingDate(onOrAfter: day(2026, 9, 14), plan: billing(day(2026, 9, 2), .week), calendar: jst) == day(2026, 9, 16))
        // 2週ごと: 9/2 → 9/16 → 9/30。
        #expect(BillingSchedule.nextBillingDate(onOrAfter: day(2026, 9, 14), plan: billing(day(2026, 9, 2), .week, interval: 2), calendar: jst) == day(2026, 9, 16))
        #expect(BillingSchedule.nextBillingDate(onOrAfter: day(2026, 9, 17), plan: billing(day(2026, 9, 2), .week, interval: 2), calendar: jst) == day(2026, 9, 30))
    }

    @Test func farPastAnchor() {
        #expect(BillingSchedule.nextBillingDate(onOrAfter: day(2026, 9, 14), plan: billing(day(2000, 1, 31)), calendar: jst) == day(2026, 9, 30))
    }

    @Test func trialStateAndFirstBilling() {
        let trialEnd = day(2026, 9, 20)
        let plan = billing(BillingSchedule.firstBillingDate(afterTrialEnd: trialEnd, calendar: jst), trialEnd: trialEnd)
        #expect(plan.anchorDate == day(2026, 9, 21))
        #expect(BillingSchedule.state(of: plan, today: at(2026, 9, 20, 23), calendar: jst) == .trial)
        #expect(BillingSchedule.state(of: plan, today: day(2026, 9, 21), calendar: jst) == .active)
        #expect(BillingSchedule.nextBillingDate(onOrAfter: day(2026, 9, 14), plan: plan, calendar: jst) == day(2026, 9, 21))
    }

    @Test func billingDatesInRange() {
        let plan = billing(day(2026, 1, 31))
        #expect(BillingSchedule.billingDates(from: day(2026, 2, 1), through: day(2026, 4, 30), plan: plan, calendar: jst)
            == [day(2026, 2, 28), day(2026, 3, 31), day(2026, 4, 30)])
        #expect(BillingSchedule.upcoming(2, from: day(2026, 3, 1), plan: plan, calendar: jst) == [day(2026, 3, 31), day(2026, 4, 30)])
    }

    @Test func paidCount() {
        let plan = billing(day(2026, 1, 31))
        #expect(BillingSchedule.paidCount(plan: plan, today: at(2026, 4, 30, 8), calendar: jst) == 4)
        #expect(BillingSchedule.paidCount(plan: plan, today: day(2026, 4, 29), calendar: jst) == 3)
        #expect(BillingSchedule.paidCount(plan: plan, today: day(2026, 1, 1), calendar: jst) == 0)
        // 解約済みは解約日までで数える。
        #expect(BillingSchedule.paidCount(plan: billing(day(2026, 1, 31), cancelledAt: day(2026, 3, 15)), today: day(2026, 9, 1), calendar: jst) == 2)
    }

    @Test func cancelledHasNoSchedule() {
        let plan = billing(day(2026, 1, 31), cancelledAt: day(2026, 3, 15))
        #expect(BillingSchedule.state(of: plan, today: day(2026, 9, 1), calendar: jst) == .cancelled)
        #expect(BillingSchedule.nextBillingDate(onOrAfter: day(2026, 9, 1), plan: plan, calendar: jst) == nil)
        #expect(BillingSchedule.billingDates(from: day(2026, 1, 1), through: day(2026, 12, 31), plan: plan, calendar: jst).isEmpty)
    }
}
