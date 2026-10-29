import Foundation
import SwiftData
import UserNotifications

/// 「今日は○○と△△のごはんの日」を、ごはんの日の夜にまとめて1通だけ知らせる。
/// 何匹いても1日1通にしたいので、個体ごとではなく日ごとに組み立てる。
enum FeedingAlarm {
    static let enabledKey = "alarm.enabled"
    static let hourKey = "alarm.hour"
    static let minuteKey = "alarm.minute"
    /// レオパは夜行性なので、夕方〜夜に与える人が多い。
    static let defaultHour = 19

    /// この先の何日ぶんを予約するか。アプリを開くたびに組み直す。
    static let lookaheadDays = 7

    struct Plan: Equatable {
        let day: Date
        let names: [String]
    }

    /// 日ごとに、ごはんの日にあたる個体の名前を並べる。過ぎている子は今日にまとめる。
    static func plan(for geckos: [(name: String, next: Date, interval: Int)], today: Date, calendar: Calendar = .current) -> [Plan] {
        let start = calendar.startOfDay(for: today)
        var byDay: [Date: [String]] = [:]
        for gecko in geckos {
            var day = max(calendar.startOfDay(for: gecko.next), start)
            while let offset = calendar.dateComponents([.day], from: start, to: day).day, offset < lookaheadDays {
                byDay[day, default: []].append(gecko.name)
                guard let following = calendar.date(byAdding: .day, value: max(1, gecko.interval), to: day) else { break }
                day = following
            }
        }
        return byDay.keys.sorted().map { Plan(day: $0, names: byDay[$0]!) }
    }

    static func body(for names: [String]) -> String {
        let shown = names.prefix(3).joined(separator: "・")
        return names.count > 3 ? "\(shown) ほか\(names.count - 3)匹のごはんの日です" : "\(shown)のごはんの日です"
    }

    @MainActor
    static func reschedule(context: ModelContext, now: Date = Date()) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: enabledKey) else { return }
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        let geckos = (try? context.fetch(FetchDescriptor<Gecko>())) ?? []
        let inputs = geckos.map { gecko -> (name: String, next: Date, interval: Int) in
            let status = gecko.status(now: now)
            return (gecko.name, status.nextFeeding, status.feedInterval)
        }
        let hour = defaults.object(forKey: hourKey) as? Int ?? defaultHour
        let minute = defaults.integer(forKey: minuteKey)
        let calendar = Calendar.current

        for item in plan(for: inputs, today: now, calendar: calendar) {
            guard let fireAt = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: item.day), fireAt > now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "ごはんの日"
            content.body = body(for: item.names)
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireAt),
                repeats: false
            )
            let id = "feeding-\(Int(item.day.timeIntervalSince1970))"
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }
}
