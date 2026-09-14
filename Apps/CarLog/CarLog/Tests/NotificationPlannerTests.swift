import Foundation
import Testing
@testable import CarLog

/// 通知の計画（何を・いつ・どの文面で）。
struct NotificationPlannerTests {
    private let now = at(2026, 6, 1, 12)

    private func vehicle(name: String = "プリウス", plans: [MaintenancePlan]) -> VehicleNotificationInput {
        VehicleNotificationInput(
            id: UUID(), name: name, currentOdometer: 10000, pace: nil,
            fallbackDate: nil, fallbackOdometer: 0, plans: plans
        )
    }

    @Test func onlyEnabledItemsWithAFutureDateAreScheduled() {
        let upcoming = plan(months: 12, lastDate: day(2025, 9, 1), title: "車検")
        let overdue = plan(months: 12, lastDate: day(2025, 1, 1), title: "税")
        let disabled = plan(months: 12, lastDate: day(2025, 9, 1), enabled: false, title: "保険")
        let noInterval = plan(lastDate: day(2025, 9, 1), title: "メモ")

        let planned = NotificationPlanner.plan(
            vehicles: [vehicle(plans: [upcoming, overdue, disabled, noInterval])], now: now, calendar: jst
        )
        #expect(planned.map(\.title) == ["車検"])
        #expect(planned[0].fireDate == at(2026, 8, 25, 9))
    }

    @Test func vehicleNameIsAddedOnlyWithMultipleVehicles() {
        let item = plan(months: 12, lastDate: day(2025, 9, 1), title: "車検")
        let single = NotificationPlanner.plan(vehicles: [vehicle(plans: [item])], now: now, calendar: jst)
        #expect(single.first?.title == "車検")

        let multiple = NotificationPlanner.plan(
            vehicles: [vehicle(name: "プリウス", plans: [item]), vehicle(name: "N-BOX", plans: [])],
            now: now, calendar: jst
        )
        #expect(multiple.first?.title == "車検（プリウス）")
    }

    @Test func identifiersAreUniquePerVehicleAndItem() {
        let a = plan(months: 12, lastDate: day(2025, 9, 1))
        let b = plan(months: 6, lastDate: day(2026, 3, 1))
        let planned = NotificationPlanner.plan(
            vehicles: [vehicle(plans: [a, b]), vehicle(plans: [a])], now: now, calendar: jst
        )
        #expect(planned.count == 3)
        #expect(Set(planned.map(\.id)).count == 3)
    }

    @Test func resultsAreSortedByFireDate() {
        let later = plan(months: 12, lastDate: day(2025, 12, 1))
        let sooner = plan(months: 12, lastDate: day(2025, 8, 1))
        let planned = NotificationPlanner.plan(vehicles: [vehicle(plans: [later, sooner])], now: now, calendar: jst)
        #expect(planned.map(\.fireDate) == planned.map(\.fireDate).sorted())
    }

    @Test func bodyStatesTheBasis() {
        let item = plan(months: 6, distance: 5000, lastDate: day(2026, 3, 20), lastOdometer: 42000)
        let status = MaintenanceDue.evaluate(
            plan: item, currentOdometer: 44000, pace: nil,
            fallbackDate: nil, fallbackOdometer: 0, now: now, calendar: jst
        )
        let body = NotificationPlanner.body(plan: item, status: status, calendar: jst)
        // 根拠（間隔と前回）が本文に含まれること。
        #expect(body.contains("6か月"))
        #expect(body.contains("5,000 km"))
        #expect(body.contains("42,000 km"))
    }
}
