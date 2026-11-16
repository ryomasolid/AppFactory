import Foundation
import SwiftData
import UserNotifications

/// 朝のお知らせの登録（中身は `MorningPlan`）。
enum Alarm {
    static let onKey = "alarm.on"
    static let hourKey = "alarm.hour"
    static let defaultHour = 8

    @MainActor
    static func reschedule(_ context: ModelContext, now: Date = Date()) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let defaults = UserDefaults.standard
        guard !Demo.on, defaults.bool(forKey: onKey) else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let cal = Calendar.current
        let birds = (try? context.fetch(FetchDescriptor<Bird>(sortBy: [SortDescriptor(\.sortIndex)]))) ?? []
        let weighedToday = !birds.isEmpty && birds.allSatisfy { $0.log(on: now, calendar: cal)?.grams != nil }
        var chores: [(bird: String, kind: ChoreKind, due: Date)] = []
        for bird in birds {
            for kind in ChoreKind.allCases {
                let last = (bird.chores ?? []).filter { $0.kind == kind }.map(\.doneOn).max()
                if let next = ChoreClock.due(kind: kind, last: last, now: now, calendar: cal).next {
                    chores.append((bird.name, kind, next))
                }
            }
        }
        let hour = defaults.object(forKey: hourKey) as? Int ?? defaultHour
        for morning in MorningPlan.plan(birdNames: birds.map(\.name), weighedToday: weighedToday, chores: chores, today: now, calendar: cal) {
            guard let fire = cal.date(bySettingHour: hour, minute: 0, second: 0, of: morning.day), fire > now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "インコ帳"
            content.body = morning.body
            content.sound = .default
            let when = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            try? await center.add(UNNotificationRequest(
                identifier: "morning-\(when.month!)-\(when.day!)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: false)
            ))
        }
    }

    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }
}
