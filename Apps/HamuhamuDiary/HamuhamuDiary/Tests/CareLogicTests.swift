import Foundation
import Testing
@testable import HamuhamuDiary

struct HamsterAgeTests {
    @Test(arguments: [
        (day(2026, 6, 1), "0ヶ月"),
        (day(2026, 4, 25), "1ヶ月"),
        (day(2025, 6, 1), "1歳"),
        (day(2024, 2, 1), "2歳4ヶ月"),
    ])
    func formatsYearsAndMonths(birth: Date, expected: String) {
        #expect(HamsterAge.text(birthDate: birth, at: day(2026, 6, 20)) == expected)
    }
}

struct ReminderStatusTests {
    private let now = at(2026, 6, 20, 12)

    @Test func thresholdsMatchTheOldApp() {
        // 14日サイクル: 11日目までは良好、12日目（8割超）からもうすぐ、14日目で交換時期。
        #expect(ReminderStatus.evaluate(lastDate: at(2026, 6, 9, 8), cycleDays: 14, now: now, calendar: jst).state == .ok)
        #expect(ReminderStatus.evaluate(lastDate: at(2026, 6, 8, 8), cycleDays: 14, now: now, calendar: jst).state == .soon)
        #expect(ReminderStatus.evaluate(lastDate: at(2026, 6, 6, 8), cycleDays: 14, now: now, calendar: jst).state == .due)
    }

    @Test func neverReplacedIsDue() {
        let status = ReminderStatus.evaluate(lastDate: nil, cycleDays: 7, now: now, calendar: jst)
        #expect(status.state == .due)
        #expect(status.dueDate == nil)
        #expect(status.progress == 1)
    }

    @Test func dueDateIsLastDatePlusCycle() {
        let status = ReminderStatus.evaluate(lastDate: at(2026, 6, 10, 21), cycleDays: 7, now: now, calendar: jst)
        #expect(status.dueDate == at(2026, 6, 17, 0))
        #expect(status.daysPassed == 10)
    }
}

struct WeightSeriesTests {
    @Test func onePointPerDayUsingTheLatestEntry() {
        let points = WeightSeries.points([
            (at(2026, 6, 2, 9), 40.0, at(2026, 6, 2, 9)),
            (at(2026, 6, 1, 9), 39.0, at(2026, 6, 1, 9)),
            (at(2026, 6, 2, 9), 41.0, at(2026, 6, 2, 21)),
            (at(2026, 6, 3, 9), nil, at(2026, 6, 3, 9)),
        ], calendar: jst)
        #expect(points.map(\.weight) == [39.0, 41.0])
    }

    @Test func changeIsFirstToLastRounded() {
        let points = [WeightPoint(date: day(2026, 6, 1), weight: 39.4), WeightPoint(date: day(2026, 6, 9), weight: 40.1)]
        #expect(WeightSeries.change(points) == 0.7)
        #expect(WeightSeries.change(Array(points.prefix(1))) == nil)
    }

    @Test func rangeFiltersByDays() {
        let points = [WeightPoint(date: at(2026, 3, 1, 0), weight: 38), WeightPoint(date: at(2026, 6, 10, 0), weight: 40)]
        #expect(WeightSeries.filter(points, range: .month, now: at(2026, 6, 20, 12), calendar: jst).count == 1)
        #expect(WeightSeries.filter(points, range: .all, now: at(2026, 6, 20, 12), calendar: jst).count == 2)
    }

    @Test func yDomainNeverCollapses() {
        let flat = [WeightPoint(date: day(2026, 6, 1), weight: 40), WeightPoint(date: day(2026, 6, 2), weight: 40)]
        let domain = WeightSeries.yDomain(flat)
        #expect(domain.lowerBound < 40 && domain.upperBound > 40)
    }
}

struct ReviewPolicyTests {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    @Test func asksAtMilestonesOnly() {
        #expect(!ReviewPolicy.shouldRequest(recordCount: 2, lastRequestedCount: nil, lastRequestedAt: nil, now: now))
        #expect(ReviewPolicy.shouldRequest(recordCount: 3, lastRequestedCount: nil, lastRequestedAt: nil, now: now))
        // 次のマイルストーン（15）に届くまでは出さない。
        #expect(!ReviewPolicy.shouldRequest(recordCount: 10, lastRequestedCount: 3, lastRequestedAt: nil, now: now))
    }

    @Test func waitsAtLeastSixtyDays() {
        let recently = now.addingTimeInterval(-30 * 86_400)
        let longAgo = now.addingTimeInterval(-90 * 86_400)
        #expect(!ReviewPolicy.shouldRequest(recordCount: 15, lastRequestedCount: 3, lastRequestedAt: recently, now: now))
        #expect(ReviewPolicy.shouldRequest(recordCount: 15, lastRequestedCount: 3, lastRequestedAt: longAgo, now: now))
    }
}

struct NotificationPlannerTests {
    private let now = at(2026, 6, 20, 12)

    private func reminder(_ key: String, last: Date?, cycle: Int = 7) -> ReminderInput {
        ReminderInput(key: key, name: "床材", emoji: "🌿", cycleDays: cycle, lastDate: last)
    }

    @Test func nothingWhenBothAreOff() {
        let planned = NotificationPlanner.plan(
            reminders: [reminder("a", last: at(2026, 6, 18, 9))], remindersEnabled: false, dailyEnabled: false,
            dailyHour: 20, hamsterName: "もち", now: now, calendar: jst
        )
        #expect(planned.isEmpty)
    }

    @Test func onlyFutureDueDatesAreScheduledAtNine() {
        let planned = NotificationPlanner.plan(
            reminders: [reminder("future", last: at(2026, 6, 18, 21)), reminder("overdue", last: at(2026, 6, 1, 9)), reminder("unset", last: nil)],
            remindersEnabled: true, dailyEnabled: false, dailyHour: 20, hamsterName: nil, now: now, calendar: jst
        )
        #expect(planned.map(\.id) == ["reminder-future"])
        #expect(planned.first?.fireDate == at(2026, 6, 25, 9))
    }

    @Test func dailyUsesTheHamsterName() {
        let planned = NotificationPlanner.plan(
            reminders: [], remindersEnabled: false, dailyEnabled: true, dailyHour: 21, hamsterName: "もち", now: now, calendar: jst
        )
        #expect(planned.count == 1)
        #expect(planned.first?.dailyHour == 21)
        #expect(planned.first?.title.contains("もち") == true)
    }
}
