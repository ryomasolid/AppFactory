import Foundation
import Testing
@testable import GomiAlarm

/// 通知の本数・文面・64件上限の扱い。
/// 「通知が来ない」はこのアプリの致命傷なので、モードの切り替わりと予算の切り方を固定する。
struct NotificationPlannerTests {

    // 2026年9月1日(火) 9:00 を「いま」とする。月=7,14,21,28／水=2,9,16,23,30／金=4,11,18,25
    private let now = at(2026, 9, 1, 9)

    private func kind(
        _ name: String,
        _ specs: [RuleSpec],
        note: String = "",
        sortOrder: Int = 0,
        evening: TimeOfDay? = nil,
        morning: TimeOfDay? = nil
    ) -> KindPlan {
        KindPlan(
            name: name, note: note, sortOrder: sortOrder, specs: specs,
            eveningTime: evening, morningTime: morning
        )
    }

    private func plan(
        _ kinds: [KindPlan], _ settings: NotificationSettings = .default, windowDays: Int = 120
    ) -> NotificationPlan {
        NotificationPlanner.plan(
            kinds: kinds, settings: settings, now: now, windowDays: windowDays, calendar: jst
        )
    }

    // MARK: - モードA（毎週＝くり返しトリガで永続）

    @Test func allWeeklyRulesUseRepeatingTriggers() {
        let result = plan([
            kind("燃えるゴミ", [RuleSpec(frequency: .weekly, weekdays: [.monday, .thursday])]),
            kind("プラ", [RuleSpec(frequency: .weekly, weekdays: [.friday])], sortOrder: 1),
        ])
        // 収集曜日3つ × 前夜/当日朝 = 6本。これだけで永続的に鳴り続ける。
        #expect(result.notifications.count == 6)
        #expect(result.isPermanent)
        #expect(!result.truncated)
        #expect(result.notifications.allSatisfy { $0.trigger.fireWeekday != nil })
    }

    @Test func eveningNotificationFiresOnThePreviousDay() {
        let result = plan([kind("燃えるゴミ", [RuleSpec(frequency: .weekly, weekdays: [.monday])])])
        let evening = result.notifications.first { $0.timing == .evening }
        let morning = result.notifications.first { $0.timing == .morning }
        // 月曜の収集 → 前夜通知は日曜、当日朝の通知は月曜。
        #expect(evening?.trigger == .weeklyRepeating(fireWeekday: .sunday, time: TimeOfDay(hour: 20, minute: 0)))
        #expect(morning?.trigger == .weeklyRepeating(fireWeekday: .monday, time: TimeOfDay(hour: 6, minute: 30)))
        #expect(evening?.title == "明日は 燃えるゴミ の日")
        #expect(morning?.title == "今日は 燃えるゴミ の日")
    }

    @Test func kindsOnTheSameDayAreMergedIntoOneNotification() {
        let result = plan([
            kind("燃えるゴミ", [RuleSpec(frequency: .weekly, weekdays: [.monday])], sortOrder: 0),
            kind("プラ", [RuleSpec(frequency: .weekly, weekdays: [.monday])], sortOrder: 1),
        ])
        // 同じ月曜・同じ時刻なので1本にまとめる（前夜＋当日朝の2本だけ）。
        #expect(result.notifications.count == 2)
        let morning = result.notifications.first { $0.timing == .morning }
        #expect(morning?.title == "今日は 燃えるゴミ・プラ の日")
        #expect(morning?.kindIDs.count == 2)
    }

    @Test func notesAreAppendedToTheBody() {
        let result = plan([
            kind("プラ", [RuleSpec(frequency: .weekly, weekdays: [.friday])], note: "キャップは外す")
        ])
        let evening = result.notifications.first { $0.timing == .evening }
        #expect(evening?.body == "今のうちにまとめておきましょう。（キャップは外す）")
    }

    @Test func customTimeIsNotMergedWithDefaultTime() {
        let result = plan([
            kind("燃えるゴミ", [RuleSpec(frequency: .weekly, weekdays: [.monday])], sortOrder: 0),
            kind(
                "プラ", [RuleSpec(frequency: .weekly, weekdays: [.monday])], sortOrder: 1,
                morning: TimeOfDay(hour: 5, minute: 0)
            ),
        ])
        // 前夜は同時刻で1本、当日朝は 6:30 と 5:00 に分かれて2本 → 合計3本。
        #expect(result.notifications.count == 3)
        #expect(result.notifications.filter { $0.timing == .morning }.count == 2)
    }

    @Test func disabledTimingsAreSkipped() {
        var settings = NotificationSettings.default
        settings.eveningEnabled = false
        let result = plan([kind("燃えるゴミ", [RuleSpec(frequency: .weekly, weekdays: [.monday])])], settings)
        #expect(result.notifications.count == 1)
        #expect(result.notifications.allSatisfy { $0.timing == .morning })
    }

    @Test func emptyInputProducesEmptyPlan() {
        #expect(plan([]).notifications.isEmpty)
        // ルール未設定の種類だけでも空。
        #expect(plan([kind("燃えるゴミ", [])]).notifications.isEmpty)
    }

    // MARK: - モードB（具体日を列挙）

    @Test func nonWeeklyRuleSwitchesToDatedNotifications() {
        let result = plan([
            kind("燃えるゴミ", [RuleSpec(frequency: .weekly, weekdays: [.monday])], sortOrder: 0),
            kind(
                "資源ごみ",
                [RuleSpec(frequency: .nthWeekday, weekdays: [.wednesday], nthWeeks: [.second, .fourth])],
                sortOrder: 1
            ),
        ])
        #expect(!result.isPermanent)
        #expect(result.notifications.allSatisfy { $0.trigger.fireDate != nil })
        // 最初に鳴るのは 9/7(月) の前夜 = 9/6 20:00。
        #expect(result.notifications.first?.trigger.fireDate == at(2026, 9, 6, 20))
        #expect(result.coveredThrough != nil)
    }

    @Test func pastFireDatesAreDropped() {
        // 「いま」が 9/1 9:00 なので、9/1 の当日朝(6:30)はもう過ぎている。
        let result = plan([kind("缶・瓶", [RuleSpec(frequency: .once, anchorDate: day(2026, 9, 1))])])
        #expect(result.notifications.isEmpty)
    }

    @Test func holidaysAreSkippedWhenSettingIsOn() {
        var settings = NotificationSettings.default
        settings.skipHolidays = true
        let result = plan([kind("燃えるゴミ", [RuleSpec(frequency: .weekly, weekdays: [.monday])])], settings)
        // 毎週ルールでも祝日除外のため具体日モードになる。
        #expect(!result.isPermanent)
        // 9/21 は敬老の日なので収集日から外れる。
        let dates = Set(result.notifications.compactMap(\.collectionDate))
        #expect(dates.contains(day(2026, 9, 7)))
        #expect(!dates.contains(day(2026, 9, 21)))
    }

    @Test func budgetTruncatesToNearestNotifications() {
        // 平日5日＋単発 → 具体日モードで本数が上限を超える。
        let result = plan([
            kind(
                "燃えるゴミ",
                [RuleSpec(frequency: .weekly, weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday])],
                sortOrder: 0
            ),
            kind("粗大ごみ", [RuleSpec(frequency: .once, anchorDate: day(2026, 10, 3))], sortOrder: 1),
        ])
        #expect(result.truncated)
        #expect(result.notifications.count == NotificationPlanner.budget)
        // 近い順に残す。
        let dates = result.notifications.map(\.nextFireDate)
        #expect(dates == dates.sorted())
        #expect(dates.first == at(2026, 9, 1, 20))   // 9/2(水) の前夜
    }
}

private extension PlannedNotification.Trigger {
    var fireWeekday: Weekday? {
        if case let .weeklyRepeating(weekday, _) = self { return weekday }
        return nil
    }

    var fireDate: Date? {
        if case let .oneShot(date) = self { return date }
        return nil
    }
}
