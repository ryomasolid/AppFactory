import Foundation
import SwiftData
import UserNotifications

/// 朝のお知らせ（これから7日ぶん）。世話の記録や器具を変えるたびに入れなおす。
enum Reminders {
    static let enabledKey = "reminders.enabled"
    static let hourKey = "reminders.hour"
    static let defaultHour = 8

    @MainActor
    static func refresh(_ context: ModelContext, now: Date = Date()) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: (0..<7).map { "kame-morning-\($0)" })
        let defaults = UserDefaults.standard
        guard !Sample.isOn, defaults.bool(forKey: enabledKey) else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let cal = Calendar.current
        let turtles = (try? context.fetch(FetchDescriptor<Turtle>(sortBy: [SortDescriptor(\.order)]))) ?? []
        let gears = (try? context.fetch(FetchDescriptor<Gear>())) ?? []
        let hour = defaults.object(forKey: hourKey) as? Int ?? defaultHour

        for offset in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: now)),
                  let fire = cal.date(bySettingHour: hour, minute: 0, second: 0, of: day),
                  fire > now else { continue }
            var lines: [MorningNote.Line] = []
            for turtle in turtles {
                for due in DueList.make(for: turtle, now: day, calendar: cal) where due.isDue {
                    // 何日もすぎた世話は毎朝くり返さず、期日の朝ときょうだけ。
                    if offset > 0, due.late > 0 { continue }
                    lines.append(.init(turtle: turtle.name, task: MorningNote.taskName(due.task)))
                }
            }
            let gearNames = gears.filter {
                GearLife.daysLeft(installedOn: $0.installedOn, lifeDays: $0.lifeDays, now: day, calendar: cal) == 0
                    || (offset == 0 && GearLife.daysLeft(installedOn: $0.installedOn, lifeDays: $0.lifeDays, now: day, calendar: cal) < 0)
            }.map(\.name)
            guard let body = MorningNote.body(lines: lines, gearNames: gearNames) else { continue }

            let content = UNMutableNotificationContent()
            content.title = "きょうのカメの世話"
            content.body = body
            content.sound = .default
            let parts = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            try? await center.add(UNNotificationRequest(
                identifier: "kame-morning-\(offset)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            ))
        }
    }

    static func askPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }
}
