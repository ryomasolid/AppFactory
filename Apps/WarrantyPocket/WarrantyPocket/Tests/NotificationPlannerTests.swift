import Foundation
import Testing
@testable import WarrantyPocket

struct NotificationPlannerTests {
    let now = at(2026, 9, 1, 12)
    let settings = NotificationSettings(timing: .thirtyAndSeven, hour: 9, minute: 0)

    @Test func thirtyAndSevenDaysBeforeAtConfiguredTime() {
        // 最終日 2026/10/14 → 9/14 9:00 と 10/7 9:00
        let planned = NotificationPlanner.plan(
            items: [input(purchased: day(2025, 10, 15))], settings: settings, now: now, calendar: jst
        )
        #expect(planned.map(\.fireDate) == [at(2026, 9, 14, 9), at(2026, 10, 7, 9)])
        #expect(planned.first?.title == "エアコンの保証がまもなく終わります")
        #expect(planned.first?.body.contains("2026/10/14") == true)
        #expect(planned.first?.body.contains("あと30日") == true)
    }

    @Test func pastNotificationsAreSkipped() {
        // 最終日 2026/9/10 → 30日前（8/11）は過ぎているので7日前（9/3）だけ。
        let planned = NotificationPlanner.plan(
            items: [input(purchased: day(2025, 9, 11))], settings: settings, now: now, calendar: jst
        )
        #expect(planned.map(\.fireDate) == [at(2026, 9, 3, 9)])
    }

    @Test func extendedWarrantyIsPlannedSeparatelyWithProvider() {
        let planned = NotificationPlanner.plan(
            items: [input(purchased: day(2025, 10, 15), extended: 60, provider: "サンプル電機")],
            settings: settings, now: now, calendar: jst
        )
        #expect(planned.count == 4)
        #expect(Set(planned.map(\.id)).count == 4)
        #expect(planned.last?.body.contains("延長保証（サンプル電機）") == true)
        #expect(planned.last?.fireDate == at(2030, 10, 7, 9))
    }

    @Test func archivedItemsAndOffSettingPlanNothing() {
        #expect(NotificationPlanner.plan(
            items: [input(purchased: day(2025, 10, 15), archived: true)], settings: settings, now: now, calendar: jst
        ).isEmpty)
        #expect(NotificationPlanner.plan(
            items: [input(purchased: day(2025, 10, 15))],
            settings: NotificationSettings(timing: .off), now: now, calendar: jst
        ).isEmpty)
    }

    @Test func sevenOnly() {
        let planned = NotificationPlanner.plan(
            items: [input(purchased: day(2025, 10, 15))],
            settings: NotificationSettings(timing: .sevenOnly, hour: 20, minute: 30), now: now, calendar: jst
        )
        #expect(planned.map(\.fireDate) == [at(2026, 10, 7, 20, 30)])
    }

    @Test func budgetKeepsTheNearestSixty() {
        // 50商品 × 2回 = 100件 → 近い順に60件。
        let items = (0..<50).map { index in
            input(name: "商品\(index)", purchased: jst.date(byAdding: .day, value: index * 3, to: day(2025, 10, 1)) ?? now)
        }
        let planned = NotificationPlanner.plan(items: items, settings: settings, now: now, calendar: jst)
        #expect(planned.count == NotificationPlanner.budget)
        #expect(planned.map(\.fireDate) == planned.map(\.fireDate).sorted())
        let all = NotificationPlanner.plan(items: items, settings: settings, now: now, calendar: jst)
        #expect(all.last?.fireDate == planned.last?.fireDate)
    }

    @Test func itemsWithoutWarrantyAreSkipped() {
        #expect(NotificationPlanner.plan(
            items: [input(purchased: day(2025, 10, 15), warranty: nil)], settings: settings, now: now, calendar: jst
        ).isEmpty)
    }
}
