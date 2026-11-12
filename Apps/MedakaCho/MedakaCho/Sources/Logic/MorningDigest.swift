import Foundation
import SwiftData
import UserNotifications

/// 朝に1通だけ「今日の水換え」と「孵りそうな卵」を知らせる。容器がいくつあっても1日1通。
enum MorningDigest {
    static let onKey = "digest.on"
    static let hourKey = "digest.hour"
    static let minuteKey = "digest.minute"
    /// 屋外の容器を見て回るのは朝が多い。
    static let defaultHour = 7
    static let daysAhead = 7

    struct Item: Equatable {
        let day: Date
        let water: [String]
        let hatch: Int
    }

    /// 日ごとの仕事を組む。過ぎている水換えは今日に寄せる。
    static func schedule(water: [(name: String, due: Date)], hatchDays: [Date], today: Date, calendar: Calendar = .current) -> [Item] {
        let start = calendar.startOfDay(for: today)
        var result: [Item] = []
        for offset in 0..<daysAhead {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            let names = water.filter { item in
                let due = calendar.startOfDay(for: item.due)
                return offset == 0 ? due <= day : due == day
            }.map(\.name)
            let hatch = hatchDays.filter { calendar.startOfDay(for: $0) == day }.count
            if !names.isEmpty || hatch > 0 { result.append(Item(day: day, water: names, hatch: hatch)) }
        }
        return result
    }

    static func message(for item: Item) -> String {
        var lines: [String] = []
        if !item.water.isEmpty {
            let head = item.water.prefix(3).joined(separator: "・")
            lines.append(item.water.count > 3 ? "水換え: \(head) ほか\(item.water.count - 3)つ" : "水換え: \(head)")
        }
        if item.hatch > 0 { lines.append("卵が孵りそう: \(item.hatch)組") }
        return lines.joined(separator: "\n")
    }

    @MainActor
    static func refresh(context: ModelContext, now: Date = Date()) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: onKey) else { return }
        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        let vessels = (try? context.fetch(FetchDescriptor<Vessel>())) ?? []
        let batches = (try? context.fetch(FetchDescriptor<EggBatch>())) ?? []
        let water = vessels.filter { $0.headcount > 0 }.map { ($0.name, VesselState(vessel: $0, now: now).waterDue) }
        let hatchDays = batches.filter(\.isOpen).compactMap { HatchClock.expectedDay(collectedOn: $0.collectedOn, celsius: $0.celsius) }

        let calendar = Calendar.current
        let hour = defaults.object(forKey: hourKey) as? Int ?? defaultHour
        let minute = defaults.integer(forKey: minuteKey)
        for item in schedule(water: water, hatchDays: hatchDays, today: now, calendar: calendar) {
            guard let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: item.day), fire > now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "今日のめだか"
            content.body = message(for: item)
            content.sound = .default
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let request = UNNotificationRequest(
                identifier: "digest-\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
            )
            try? await center.add(request)
        }
    }

    static func askPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }
}
