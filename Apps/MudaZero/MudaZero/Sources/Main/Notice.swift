import Foundation
import SwiftData
import UserNotifications

/// 夜のお知らせ（文面は `NightPlan`）。きょうをしめたら、きょうの分は出さない。
enum Notice {
    static let onKey = "notice.on"
    static let hourKey = "notice.hour"
    static let defaultHour = 21

    @MainActor
    static func reschedule(_ context: ModelContext, now: Date = Date()) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let defaults = UserDefaults.standard
        guard !Demo.on, defaults.bool(forKey: onKey) else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let cal = Calendar.current
        let book = Book.load(context, calendar: cal)
        let hour = defaults.object(forKey: hourKey) as? Int ?? defaultHour
        for night in NightPlan.plan(book: book, today: now) {
            guard let fire = cal.date(bySettingHour: hour, minute: 0, second: 0, of: night.day), fire > now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "ムダゼロ"
            content.body = night.body
            content.sound = .default
            let when = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            try? await center.add(UNNotificationRequest(
                identifier: "night-\(when.month!)-\(when.day!)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: false)
            ))
        }
    }

    static func ask() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }
}

extension Book {
    @MainActor
    static func load(_ context: ModelContext, calendar: Calendar = .current) -> Book {
        let spends = (try? context.fetch(FetchDescriptor<Spend>())) ?? []
        let marks = (try? context.fetch(FetchDescriptor<DayMark>())) ?? []
        return Book(entries: spends.map(\.entry), closedDays: marks.map(\.day), calendar: calendar)
    }

    init(spends: [Spend], marks: [DayMark], calendar: Calendar = .current) {
        self.init(entries: spends.map(\.entry), closedDays: marks.map(\.day), calendar: calendar)
    }
}
