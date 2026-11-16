import Foundation
import SwiftData
import UserNotifications

/// 通知の登録。中身は `DailyNudge` で組む。
enum Reminders {
    static let morningKey = "remind.morning"
    static let eveningKey = "remind.evening"
    static let morningHour = 8
    static let eveningHour = 20

    @MainActor
    static func rebuild(_ context: ModelContext, now: Date = Date()) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard !Showcase.isOn else { return }
        let defaults = UserDefaults.standard
        let wantsMorning = defaults.bool(forKey: morningKey), wantsEvening = defaults.bool(forKey: eveningKey)
        guard wantsMorning || wantsEvening else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let calendar = Calendar.current
        let dogs = (try? context.fetch(FetchDescriptor<Dog>(sortBy: [SortDescriptor(\.order)]))) ?? []

        if wantsMorning {
            var care: [DailyNudge.DueThing] = []
            var cuts: [DailyNudge.DueThing] = []
            for dog in dogs {
                for kind in CareKind.allCases {
                    let history = dog.shots(of: kind)
                    // 一度も記録していない予防は、その子では使っていないものとして知らせない。
                    guard let last = history.first?.on,
                          let due = PreventionPlan.next(kind: kind, last: last, season: SeasonSetting.load(kind), today: now, calendar: calendar)
                    else { continue }
                    care.append(.init(dog: dog.name, what: kind.label, day: due))
                }
                let cutDays = dog.trimHistory.filter(\.menu.cutsCoat).map(\.on)
                if let due = TrimRhythm.status(cuts: cutDays, now: now, calendar: calendar).nextDue {
                    cuts.append(.init(dog: dog.name, what: "トリミング", day: due))
                }
            }
            for morning in DailyNudge.mornings(prevention: care, trims: cuts, today: now, calendar: calendar) {
                await add(center, id: "morning", day: morning.day, hour: morningHour, title: "今日のわんこケア", body: DailyNudge.body(morning), now: now, calendar: calendar)
            }
        }

        if wantsEvening {
            let writtenToday = dogs.contains { $0.page(on: now, calendar: calendar) != nil }
            let names = dogs.prefix(2).map(\.name).joined(separator: "・")
            for day in DailyNudge.eveningDays(writtenToday: writtenToday, today: now, calendar: calendar) {
                await add(center, id: "evening", day: day, hour: eveningHour, title: "きょうの\(names.isEmpty ? "わんこ" : names)は どうだった？", body: "1行だけでも、写真1枚だけでも。あとで見返すと宝物になります。", now: now, calendar: calendar)
            }
        }
    }

    private static func add(_ center: UNUserNotificationCenter, id: String, day: Date, hour: Int, title: String, body: String, now: Date, calendar: Calendar) async {
        guard let fire = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day), fire > now else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
        let request = UNNotificationRequest(
            identifier: "\(id)-\(parts.year!)-\(parts.month!)-\(parts.day!)",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        )
        try? await center.add(request)
    }

    static func ask() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }
}
