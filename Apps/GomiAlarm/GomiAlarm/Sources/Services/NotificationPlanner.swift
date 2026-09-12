import Foundation

/// 1本の通知の予定。UserNotifications には依存しない値型なので、内容と本数をテストで検証できる。
struct PlannedNotification: Equatable, Sendable, Identifiable {
    enum Trigger: Equatable, Sendable {
        /// 毎週くり返し（曜日＋時刻）。1本で永続的に鳴り続ける。
        case weeklyRepeating(fireWeekday: Weekday, time: TimeOfDay)
        /// 具体的な日時に1回だけ。
        case oneShot(fireDate: Date)
    }

    var id: String
    var title: String
    var body: String
    var trigger: Trigger
    /// 次に鳴る日時。予算を切るときの優先順位に使う。
    var nextFireDate: Date
    var timing: NotificationTiming
    var kindIDs: [UUID]
    /// 対象の収集日（oneShot のときだけ）。
    var collectionDate: Date?
}

/// 通知の計画（本数・カバー範囲）。
struct NotificationPlan: Equatable, Sendable {
    var notifications: [PlannedNotification] = []
    /// くり返しトリガだけで構成され、再構築なしで鳴り続けるか。
    var isPermanent: Bool = false
    /// 1回きりの通知でカバーできている最後の収集日。`isPermanent` なら nil。
    var coveredThrough: Date?
    /// 上限に達して切り捨てたか（設定画面で警告を出す）。
    var truncated: Bool = false
}

/// 登録する通知の中身を決める純粋ロジック。
///
/// ## iOS の保留通知は1アプリ64件まで
/// 前夜＋当日朝の2段構成だと本数が倍になり、素朴に全部登録すると簡単にあふれて
/// 「通知が来ない」＝アプリの価値が消える。そこで次の2モードを使い分ける。
///
/// - **モードA（永続）**: すべてのルールが「毎週」で、祝日スキップがオフのとき。
///   曜日＋時刻のくり返しトリガだけで表現できるので、最大でも 7曜日 × 2タイミング。
///   一度登録すれば再構築が不要。
/// - **モードB（窓）**: 隔週・第n曜日・毎月◯日・単発が1つでもあるか、祝日スキップがオンのとき。
///   くり返しトリガで表現できないので具体日を列挙し、近い順に予算ぶんだけ登録する。
///   アプリ起動時（および将来の BGAppRefreshTask）で作り直す。
///
/// 同じ日・同じ時刻に複数の種類が重なる場合は1本にまとめる（「今日は 燃えるゴミ・プラ の日」）。
/// 本数の節約になり、通知が連続して鳴るうるささも避けられる。
enum NotificationPlanner {

    /// 使用する上限。64 きっかりではなく余裕を持たせる。
    static let budget = 60

    static func plan(
        kinds: [KindPlan],
        settings: NotificationSettings,
        now: Date = Date(),
        windowDays: Int = 120,
        calendar: Calendar = .current,
        holidays: Set<Date>? = nil
    ) -> NotificationPlan {
        let active = kinds.filter { !$0.specs.isEmpty }
        let timings = enabledTimings(settings)
        guard !active.isEmpty, !timings.isEmpty else { return NotificationPlan() }

        let allWeekly = active.allSatisfy { $0.specs.allSatisfy { $0.frequency == .weekly } }
        if allWeekly && !settings.skipHolidays {
            return weeklyPlan(kinds: active, timings: timings, settings: settings, now: now, calendar: calendar)
        }
        return datedPlan(
            kinds: active, timings: timings, settings: settings,
            now: now, windowDays: windowDays, calendar: calendar, holidays: holidays
        )
    }

    // MARK: - モードA（毎週くり返し）

    private struct WeeklyKey: Hashable {
        var collectionWeekday: Weekday
        var time: TimeOfDay
        var timing: NotificationTiming
    }

    private static func weeklyPlan(
        kinds: [KindPlan],
        timings: [NotificationTiming],
        settings: NotificationSettings,
        now: Date,
        calendar: Calendar
    ) -> NotificationPlan {
        var groups: [WeeklyKey: [KindPlan]] = [:]
        for kind in kinds {
            for spec in kind.specs {
                for weekday in spec.weekdays {
                    for timing in timings {
                        let key = WeeklyKey(
                            collectionWeekday: weekday,
                            time: kind.time(for: timing, settings: settings),
                            timing: timing
                        )
                        groups[key, default: []].append(kind)
                    }
                }
            }
        }

        var notifications: [PlannedNotification] = []
        for (key, members) in groups {
            let grouped = uniqueSorted(members)
            // 前夜通知は収集日の前日に鳴らす。
            let fireWeekday = key.timing == .morning ? key.collectionWeekday : key.collectionWeekday.previous
            let components = DateComponents(
                hour: key.time.hour, minute: key.time.minute, weekday: fireWeekday.rawValue
            )
            let next = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) ?? now
            let content = content(timing: key.timing, kinds: grouped)
            notifications.append(
                PlannedNotification(
                    id: "w-\(key.timing.rawValue)-\(key.collectionWeekday.rawValue)-\(key.time.minutesFromMidnight)",
                    title: content.title,
                    body: content.body,
                    trigger: .weeklyRepeating(fireWeekday: fireWeekday, time: key.time),
                    nextFireDate: next,
                    timing: key.timing,
                    kindIDs: grouped.map(\.id),
                    collectionDate: nil
                )
            )
        }

        notifications.sort { $0.nextFireDate < $1.nextFireDate }
        let truncated = notifications.count > budget
        return NotificationPlan(
            notifications: Array(notifications.prefix(budget)),
            isPermanent: !truncated,
            coveredThrough: nil,
            truncated: truncated
        )
    }

    // MARK: - モードB（具体日を列挙）

    private struct DatedKey: Hashable {
        var collectionDate: Date
        var time: TimeOfDay
        var timing: NotificationTiming
    }

    private static func datedPlan(
        kinds: [KindPlan],
        timings: [NotificationTiming],
        settings: NotificationSettings,
        now: Date,
        windowDays: Int,
        calendar: Calendar,
        holidays: Set<Date>?
    ) -> NotificationPlan {
        let today = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: windowDays, to: today) else {
            return NotificationPlan()
        }
        let skipped: Set<Date> = settings.skipHolidays
            ? (holidays ?? HolidayCalendar.holidays(from: today, through: end, calendar: calendar))
            : []

        var groups: [DatedKey: [KindPlan]] = [:]
        for kind in kinds {
            let dates = ScheduleCalculator.occurrences(
                of: kind.specs, from: today, through: end, calendar: calendar
            )
            for date in dates where !skipped.contains(date) {
                for timing in timings {
                    let key = DatedKey(
                        collectionDate: date,
                        time: kind.time(for: timing, settings: settings),
                        timing: timing
                    )
                    groups[key, default: []].append(kind)
                }
            }
        }

        var notifications: [PlannedNotification] = []
        for (key, members) in groups {
            // 前夜通知は収集日の前日に鳴らす。
            let fireDay = key.timing == .morning
                ? key.collectionDate
                : calendar.date(byAdding: .day, value: -1, to: key.collectionDate)
            guard let fireDay,
                  let fireDate = key.time.date(on: fireDay, calendar: calendar),
                  fireDate > now
            else { continue }

            let grouped = uniqueSorted(members)
            let content = content(timing: key.timing, kinds: grouped)
            let stamp = Int(key.collectionDate.timeIntervalSince1970)
            notifications.append(
                PlannedNotification(
                    id: "d-\(key.timing.rawValue)-\(stamp)-\(key.time.minutesFromMidnight)",
                    title: content.title,
                    body: content.body,
                    trigger: .oneShot(fireDate: fireDate),
                    nextFireDate: fireDate,
                    timing: key.timing,
                    kindIDs: grouped.map(\.id),
                    collectionDate: key.collectionDate
                )
            )
        }

        notifications.sort { $0.nextFireDate < $1.nextFireDate }
        let truncated = notifications.count > budget
        let kept = Array(notifications.prefix(budget))
        return NotificationPlan(
            notifications: kept,
            isPermanent: false,
            coveredThrough: kept.compactMap(\.collectionDate).max(),
            truncated: truncated
        )
    }

    // MARK: - 共通

    private static func enabledTimings(_ settings: NotificationSettings) -> [NotificationTiming] {
        var timings: [NotificationTiming] = []
        if settings.eveningEnabled { timings.append(.evening) }
        if settings.morningEnabled { timings.append(.morning) }
        return timings
    }

    /// 同じ種類が複数ルールで重複するので、id で一意化してから表示順に並べる。
    private static func uniqueSorted(_ kinds: [KindPlan]) -> [KindPlan] {
        var seen = Set<UUID>()
        let unique = kinds.filter { seen.insert($0.id).inserted }
        return unique.sorted { ($0.sortOrder, $0.name) < ($1.sortOrder, $1.name) }
    }

    /// 通知の文面。複数の種類が重なる日は「燃えるゴミ・プラ」のように並べる。
    private static func content(
        timing: NotificationTiming, kinds: [KindPlan]
    ) -> (title: String, body: String) {
        let names = kinds.map(\.name).joined(separator: "・")
        let notes = kinds.map(\.note).filter { !$0.isEmpty }.joined(separator: "／")
        let suffix = notes.isEmpty ? "" : "（\(notes)）"
        switch timing {
        case .evening:
            return (
                String(localized: "明日は \(names) の日"),
                String(localized: "今のうちにまとめておきましょう。\(suffix)")
            )
        case .morning:
            return (
                String(localized: "今日は \(names) の日"),
                String(localized: "忘れずに出しましょう。\(suffix)")
            )
        }
    }
}
