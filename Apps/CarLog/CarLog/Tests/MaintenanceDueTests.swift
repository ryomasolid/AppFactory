import Foundation
import Testing
@testable import CarLog

/// メンテの次回予定・状態・通知日時。
struct MaintenanceDueTests {
    private let now = at(2026, 6, 1, 12)
    private let pace30 = DrivingPace(kilometersPerDay: 30, days: 60, distance: 1800)

    private func evaluate(
        _ plan: MaintenancePlan, odometer: Double = 10000, pace: DrivingPace? = nil,
        fallbackDate: Date? = nil, fallbackOdometer: Double = 0
    ) -> MaintenanceStatus {
        MaintenanceDue.evaluate(
            plan: plan, currentOdometer: odometer, pace: pace,
            fallbackDate: fallbackDate, fallbackOdometer: fallbackOdometer,
            now: now, calendar: jst
        )
    }

    @Test func dateOnlyItem() {
        let status = evaluate(plan(months: 12, lastDate: day(2025, 9, 1)))
        #expect(status.dueDate == day(2026, 9, 1))
        #expect(status.dueOdometer == nil)
        #expect(status.effectiveDate == day(2026, 9, 1))
        #expect(status.remainingDays == 92)
        #expect(status.state == .ok)
    }

    @Test func distanceOnlyItemUsesProjectedDate() {
        // 残り 300km ÷ 30km/日 = 10日後。
        let status = evaluate(plan(distance: 5000, lastOdometer: 5300), odometer: 10000, pace: pace30)
        #expect(status.dueOdometer == 10300)
        #expect(status.remainingDistance == 300)
        #expect(status.projectedDate == day(2026, 6, 11))
        #expect(status.effectiveDate == day(2026, 6, 11))
    }

    @Test func earlierOfDateAndDistanceWins() {
        // 期間なら 2026/7/1、距離なら 10日後（6/11）。早いほう。
        let status = evaluate(
            plan(months: 6, distance: 5000, lastDate: day(2026, 1, 1), lastOdometer: 5300),
            odometer: 10000, pace: pace30
        )
        #expect(status.effectiveDate == day(2026, 6, 11))
    }

    @Test func overdueByDate() {
        let status = evaluate(plan(months: 12, lastDate: day(2025, 5, 20)))
        #expect(status.state == .overdue)
        #expect((status.remainingDays ?? 0) < 0)
    }

    @Test func overdueByDistanceEvenWithoutPace() {
        let status = evaluate(plan(distance: 5000, lastOdometer: 4000), odometer: 9100)
        #expect(status.state == .overdue)
        #expect(status.remainingDistance == -100)
    }

    @Test func soonWithinNoticeDays() {
        let status = evaluate(plan(months: 12, lastDate: day(2025, 6, 5), notifyDaysBefore: 7))
        #expect(status.state == .soon)
    }

    @Test func soonWithinTenPercentOfDistance() {
        // 残り 400km（5000km の 8%）。ペースが無くても距離の割合で「もうすぐ」。
        let status = evaluate(plan(distance: 5000, lastOdometer: 5400), odometer: 10000)
        #expect(status.state == .soon)
    }

    @Test func fallsBackToVehicleStartWhenNeverDone() {
        let status = evaluate(
            plan(months: 24, distance: 10000), odometer: 12000,
            fallbackDate: day(2025, 1, 10), fallbackOdometer: 11000
        )
        #expect(status.dueDate == day(2027, 1, 10))
        #expect(status.dueOdometer == 21000)
    }

    @Test func noIntervalMeansOkAndNoDates() {
        let status = evaluate(plan(lastDate: day(2020, 1, 1)))
        #expect(status.state == .ok)
        #expect(status.effectiveDate == nil)
    }

    // MARK: - 通知日時

    @Test func notifiesNDaysBeforeAtTheConfiguredTime() {
        let item = plan(months: 12, lastDate: day(2025, 9, 1), notifyDaysBefore: 7, hour: 8, minute: 30)
        let status = evaluate(item)
        #expect(MaintenanceDue.notificationDate(for: status, plan: item, now: now, calendar: jst) == at(2026, 8, 25, 8, 30))
    }

    @Test func fallsBackToTheDueDayWhenTheEarlyNoticeHasPassed() {
        // 予定は 6/4。7日前（5/28）は過ぎているので当日 9:00。
        let item = plan(months: 12, lastDate: day(2025, 6, 4), notifyDaysBefore: 7)
        let status = evaluate(item)
        #expect(MaintenanceDue.notificationDate(for: status, plan: item, now: now, calendar: jst) == at(2026, 6, 4, 9))
    }

    @Test func noNotificationOnceOverdueOrDisabled() {
        let overdue = plan(months: 12, lastDate: day(2025, 5, 1))
        #expect(MaintenanceDue.notificationDate(for: evaluate(overdue), plan: overdue, now: now, calendar: jst) == nil)

        let disabled = plan(months: 12, lastDate: day(2025, 9, 1), enabled: false)
        #expect(MaintenanceDue.notificationDate(for: evaluate(disabled), plan: disabled, now: now, calendar: jst) == nil)
    }
}
