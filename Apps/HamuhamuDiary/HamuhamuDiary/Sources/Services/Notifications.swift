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
        let name = (try? context.fetch(FetchDescriptor<HamsterProfile>()))?.first?.name
        let hour = defaults.object(forKey: NotificationSettings.dailyHourKey) as? Int ?? 20
        let planned = NotificationPlanner.plan(
            reminders: reminders,
            remindersEnabled: defaults.bool(forKey: NotificationSettings.remindersEnabledKey),
            dailyEnabled: defaults.bool(forKey: NotificationSettings.dailyEnabledKey),
            dailyHour: hour,
            hamsterName: name,
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
