import Foundation
import Testing
@testable import SubsNote

struct NotificationPlannerTests {
    let now = at(2026, 9, 14, 12)
    let settings = NotificationSettings()

    private func plan(_ inputs: [SubscriptionNotificationInput], settings: NotificationSettings? = nil) -> [PlannedNotification] {
        NotificationPlanner.plan(subscriptions: inputs, settings: settings ?? self.settings, now: now, calendar: jst)
    }

    @Test func threeDaysAndDayBeforeAtNine() {
        // 次回 9/20 → 9/17 9:00 と 9/19 9:00。
        let planned = plan([input(billing(day(2026, 8, 20)))])
        #expect(Array(planned.prefix(3)).map(\.fireDate) == [at(2026, 9, 17, 9), at(2026, 9, 19, 9), at(2026, 10, 17, 9)])
        #expect(planned.first?.title == "動画プラスの支払いが3日後です")
        #expect(planned.first?.body == "9月20日に動画プラスの支払い（¥1,590・App Store）があります。")
        #expect(planned[1].title == "動画プラスの支払いが明日です")
        #expect(Set(planned.map(\.id)).count == planned.count)
    }

    @Test func pastNotificationsAreSkipped() {
        // 今日 9/14 が支払日: 3日前も前日も過ぎているので、次は 10/11。
        let planned = plan([input(billing(day(2026, 8, 14)))])
        #expect(planned.first?.fireDate == at(2026, 10, 11, 9))
    }

    @Test func sameDayAtConfiguredTime() {
        let settings = NotificationSettings(reminderDays: [0], hour: 20, minute: 30)
        let planned = plan([input(billing(day(2026, 8, 14)))], settings: settings)
        #expect(planned.first?.fireDate == at(2026, 9, 14, 20, 30))
        #expect(planned.first?.title == "動画プラスの支払いが今日です")
    }

    @Test func trialEndIsNotifiedInsteadOfFirstBilling() {
        // 体験最終日 9/20 → 9/17 と 9/19 に体験終了。初回の支払日 9/21 の「3日前・前日」は重ねない。
        let trialEnd = day(2026, 9, 20)
        let planned = plan([input(billing(day(2026, 9, 21), trialEnd: trialEnd))])
        let trials = planned.filter(\.isTrial)
        #expect(trials.map(\.fireDate) == [at(2026, 9, 17, 9), at(2026, 9, 19, 9)])
        #expect(trials.first?.title == "動画プラスの無料体験がまもなく終わります")
        #expect(trials.first?.body == "無料体験は9月20日まで（あと3日）。続けない場合はそれまでに解約を。9月21日から 月 ¥1,590 の支払いが始まります。")
        #expect(trials.last?.body.contains("（明日が最終日）") == true)
        #expect(planned.first { !$0.isTrial }?.fireDate == at(2026, 10, 18, 9))
    }

    @Test func trialAlertsOffFallsBackToBillingReminders() {
        var settings = NotificationSettings()
        settings.trialAlerts = false
        let planned = plan([input(billing(day(2026, 9, 21), trialEnd: day(2026, 9, 20)))], settings: settings)
        #expect(!planned.contains { $0.isTrial })
        #expect(Array(planned.prefix(2)).map(\.fireDate) == [at(2026, 9, 18, 9), at(2026, 9, 20, 9)])
    }

    @Test func yearlyAlsoSevenDaysBefore() {
        let planned = plan([input(billing(day(2025, 10, 1), .year, price: 5900))])
        #expect(Array(planned.prefix(3)).map(\.fireDate) == [at(2026, 9, 24, 9), at(2026, 9, 28, 9), at(2026, 9, 30, 9)])
        #expect(planned.first?.body == "10月1日に動画プラスの支払い（¥5,900・App Store）があります。年払いの更新です。続けない場合は早めに解約の手続きを。")

        var settings = NotificationSettings()
        settings.yearlyWeekBefore = false
        #expect(plan([input(billing(day(2025, 10, 1), .year, price: 5900))], settings: settings).first?.fireDate == at(2026, 9, 28, 9))
    }

    @Test func paymentMethodOtherIsOmittedFromBody() {
        let planned = plan([input(billing(day(2026, 8, 20)), payment: .other)])
        #expect(planned.first?.body == "9月20日に動画プラスの支払い（¥1,590）があります。")
    }

    @Test func budgetKeepsNearestAndTrialsFirst() {
        // 週払い40件で予算を超えさせる。遠い体験終了（12/1）も必ず残す。
        var inputs = (0..<40).map { index in
            input(billing(jst.date(byAdding: .day, value: index % 7, to: day(2026, 9, 1)) ?? now, .week, price: 300), name: "サービス\(index)")
        }
        inputs.append(input(billing(day(2026, 12, 2), trialEnd: day(2026, 12, 1)), name: "体験中"))
        let planned = plan(inputs)
        #expect(planned.count == NotificationPlanner.budget)
        #expect(planned.map(\.fireDate) == planned.map(\.fireDate).sorted())
        #expect(planned.filter { $0.isTrial }.count == 2)
    }

    @Test func cancelledAndAllOffPlanNothing() {
        #expect(plan([input(billing(day(2026, 8, 20), cancelledAt: day(2026, 9, 1)))]).isEmpty)
        let off = NotificationSettings(reminderDays: [], trialAlerts: false, yearlyWeekBefore: false)
        #expect(plan([input(billing(day(2026, 8, 20))), input(billing(day(2026, 9, 21), trialEnd: day(2026, 9, 20)))], settings: off).isEmpty)
    }

    @Test func settingsEncoding() {
        #expect(NotificationSettings.encode([1, 3, 7]) == "7,3,1")
        #expect(NotificationSettings.decode("7,3,1") == [7, 3, 1])
        #expect(NotificationSettings.decode("") == [])
        #expect(NotificationSettings.decode("3,5,x") == [3])
    }
}

struct BackgroundRefreshPolicyTests {
    let now = at(2026, 9, 14, 12)

    private func planned(firingIn days: Double) -> [PlannedNotification] {
        [PlannedNotification(id: "a", fireDate: now.addingTimeInterval(days * 86400), title: "", body: "", isTrial: false)]
    }

    @Test func halfOfCoverageClamped() {
        #expect(BackgroundRefreshPolicy.nextRefreshDate(planned: [], now: now) == nil)
        #expect(BackgroundRefreshPolicy.nextRefreshDate(planned: planned(firingIn: 6), now: now) == now.addingTimeInterval(3 * 86400))
        #expect(BackgroundRefreshPolicy.nextRefreshDate(planned: planned(firingIn: 1), now: now) == now.addingTimeInterval(86400))
        #expect(BackgroundRefreshPolicy.nextRefreshDate(planned: planned(firingIn: 60), now: now) == now.addingTimeInterval(7 * 86400))
    }
}
