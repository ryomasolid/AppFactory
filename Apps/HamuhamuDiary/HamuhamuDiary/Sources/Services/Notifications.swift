import Foundation
import SwiftData
import UserNotifications

/// 予約する通知1件。
struct PlannedNotification: Equatable, Sendable {
    var id: String
    var title: String
    var body: String
    /// 1回きりの通知の日時。毎日の通知なら nil。
    var fireDate: Date?
    /// 毎日の通知の時刻。
    var dailyHour: Int?
}

/// 通知の設定（@AppStorage のキーも兼ねる）。
enum NotificationSettings {
    static let remindersEnabledKey = "hd.remindersEnabled"
    static let dailyEnabledKey = "hd.dailyEnabled"
    static let dailyHourKey = "hd.dailyHour"
    static let dailyHourChoices = [8, 12, 18, 20, 22]
    /// 記録がとぎれたときのお知らせ。ほかの通知と違って最初からオン（通知の許可は最初の記録のあとに求める）。
    static let inactiveEnabledKey = "hd.inactiveEnabled"
    /// 最後の記録から何日あいたら知らせるか。
    static let inactiveAfterDays = 3
    /// アプリを開かなくても届くよう、先の分まで1日1件ずつ予約しておく日数（iOS の予約上限 64 件に収まる数）。
    static let inactiveScheduleDays = 30

    /// 誕生日・お迎え記念日のお知らせ。こちらも最初からオン。
    static let anniversaryEnabledKey = "hd.anniversaryEnabled"
    /// 記念日のお知らせを何日先まで予約しておくか。
    static let anniversaryScheduleDays = 60

    static func inactiveEnabled(_ defaults: UserDefaults) -> Bool {
        defaults.object(forKey: inactiveEnabledKey) as? Bool ?? true
    }

    static func anniversaryEnabled(_ defaults: UserDefaults) -> Bool {
        defaults.object(forKey: anniversaryEnabledKey) as? Bool ?? true
    }

    /// 最初からオンの通知（設定で自分でオンにしなくても届くもの）が1つでも有効か。
    static func automaticEnabled(_ defaults: UserDefaults) -> Bool {
        inactiveEnabled(defaults) || anniversaryEnabled(defaults)
    }
    /// 交換日のお知らせは朝に出す（お世話の前に気づけるように）。
    static let reminderHour = 9
}

struct ReminderInput: Sendable {
    var key: String
    var name: String
    var emoji: String
    var cycleDays: Int
    var lastDate: Date?
}

/// 何を・いつ通知するかを決める。
enum NotificationPlanner {
    static func plan(
        reminders: [ReminderInput],
        remindersEnabled: Bool,
        dailyEnabled: Bool,
        dailyHour: Int,
        inactiveEnabled: Bool = false,
        lastRecordDate: Date? = nil,
        anniversaries: [Anniversary] = [],
        hamsterName: String?,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [PlannedNotification] {
        var result: [PlannedNotification] = []
        let name = (hamsterName?.isEmpty == false ? hamsterName : nil) ?? String(localized: "ハムちゃん")

        if dailyEnabled {
            result.append(PlannedNotification(
                id: "daily-record",
                title: String(localized: "\(name)の今日のお世話 🐹"),
                body: String(localized: "体重やごはんを記録して、成長を残しておきましょう"),
                fireDate: nil,
                dailyHour: dailyHour
            ))
        }

        // 最後の記録から3日目に1回、そのあとも記録されるまで毎日。記録すると予約し直されて止まる。
        // 毎日のリマインドがオンなら同じ時刻に毎日届いているので、重ねて出さない。
        if inactiveEnabled, !dailyEnabled, let lastRecordDate {
            let lastDay = calendar.startOfDay(for: min(lastRecordDate, now))
            let first = NotificationSettings.inactiveAfterDays
            for days in first..<(first + NotificationSettings.inactiveScheduleDays) {
                guard let day = calendar.date(byAdding: .day, value: days, to: lastDay),
                      let fire = calendar.date(bySettingHour: dailyHour, minute: 0, second: 0, of: day),
                      fire > now else { continue }
                result.append(PlannedNotification(
                    id: "inactive-\(days)",
                    title: String(localized: "\(name)の記録がお休み中です 🐹"),
                    body: String(localized: "最後の記録から\(days)日たちました。今日の様子を残しておきましょう"),
                    fireDate: fire,
                    dailyHour: nil
                ))
            }
        }

        // 記念日の朝に。`anniversaries` は呼び出し側で有効なときだけ渡す。
        for (index, anniversary) in anniversaries.enumerated() {
            guard let fire = calendar.date(bySettingHour: NotificationSettings.reminderHour, minute: 0, second: 0, of: anniversary.date),
                  fire > now else { continue }
            result.append(PlannedNotification(
                id: "anniversary-\(index)",
                title: String(localized: "\(anniversary.emoji) 今日は\(name)の\(anniversary.label)！"),
                body: String(localized: "写真を残して、シェアカードでお祝いしよう"),
                fireDate: fire,
                dailyHour: nil
            ))
        }

        if remindersEnabled {
            for reminder in reminders {
                let status = ReminderStatus.evaluate(lastDate: reminder.lastDate, cycleDays: reminder.cycleDays, now: now, calendar: calendar)
                guard let due = status.dueDate,
                      let fire = calendar.date(bySettingHour: NotificationSettings.reminderHour, minute: 0, second: 0, of: due),
                      fire > now else { continue }
                result.append(PlannedNotification(
                    id: "reminder-\(reminder.key)",
                    title: String(localized: "\(reminder.emoji) \(reminder.name)の交換時期です"),
                    body: String(localized: "前回から\(reminder.cycleDays)日たちました。交換したらアプリでリセットしてね"),
                    fireDate: fire,
                    dailyHour: nil
                ))
            }
        }
        return result
    }
}

/// 通知の許可と予約。予約は常に「全削除 → 作り直し」（件数が少ないので差分を追うより壊れにくい）。
@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()
    private init() {}

    private let center = UNUserNotificationCenter.current()

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// 未確認なら許可を求め、通知を出せるかを返す。
    func requestAuthorizationIfNeeded() async -> Bool {
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        default:
            return false
        }
    }

    /// 予約を作り直す。起動・復帰時、リマインダーや通知設定を変えたときに呼ぶ。許可ダイアログは出さない。
    func rebuild(context: ModelContext, defaults: UserDefaults = .standard, now: Date = Date()) async {
        let reminders = ((try? context.fetch(FetchDescriptor<SupplyReminder>())) ?? []).map {
            ReminderInput(key: $0.key, name: $0.name, emoji: $0.emoji, cycleDays: $0.cycleDays, lastDate: $0.lastDate)
        }
        let profile = (try? context.fetch(FetchDescriptor<HamsterProfile>()))?.first
        let anniversaries = NotificationSettings.anniversaryEnabled(defaults) && profile != nil
            ? Anniversaries.between(
                birthDate: profile?.birthDate, welcomeDate: profile?.welcomeDate,
                from: now, days: NotificationSettings.anniversaryScheduleDays
            )
            : []
        let hour = defaults.object(forKey: NotificationSettings.dailyHourKey) as? Int ?? 20
        var latest = FetchDescriptor<DiaryRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        latest.fetchLimit = 1
        let lastRecordDate = (try? context.fetch(latest))?.first?.date
        let planned = NotificationPlanner.plan(
            reminders: reminders,
            remindersEnabled: defaults.bool(forKey: NotificationSettings.remindersEnabledKey),
            dailyEnabled: defaults.bool(forKey: NotificationSettings.dailyEnabledKey),
            dailyHour: hour,
            inactiveEnabled: NotificationSettings.inactiveEnabled(defaults),
            lastRecordDate: lastRecordDate,
            anniversaries: anniversaries,
            hamsterName: profile?.name,
            now: now
        )

        center.removeAllPendingNotificationRequests()
        guard !planned.isEmpty else { return }
        switch await authorizationStatus() {
        case .authorized, .provisional, .ephemeral: break
        default: return
        }
        for notification in planned {
            try? await center.add(request(for: notification))
        }
    }

    private func request(for planned: PlannedNotification) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = planned.title
        content.body = planned.body
        content.sound = .default
        let trigger: UNCalendarNotificationTrigger
        if let hour = planned.dailyHour {
            trigger = UNCalendarNotificationTrigger(dateMatching: DateComponents(hour: hour, minute: 0), repeats: true)
        } else {
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: planned.fireDate ?? Date())
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }
        return UNNotificationRequest(identifier: planned.id, content: content, trigger: trigger)
    }
}
