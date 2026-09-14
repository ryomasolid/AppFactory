import Foundation

/// 保証期限の何日前に通知するか。
enum NotificationTiming: String, CaseIterable, Identifiable, Sendable {
    case thirtyAndSeven
    case sevenOnly
    case off

    var id: String { rawValue }

    var daysBefore: [Int] {
        switch self {
        case .thirtyAndSeven: [30, 7]
        case .sevenOnly: [7]
        case .off: []
        }
    }

    var label: String {
        switch self {
        case .thirtyAndSeven: String(localized: "30日前と7日前")
        case .sevenOnly: String(localized: "7日前のみ")
        case .off: String(localized: "通知しない")
        }
    }
}

struct NotificationSettings: Equatable, Sendable {
    var timing: NotificationTiming = .thirtyAndSeven
    var hour: Int = 9
    var minute: Int = 0
}

/// 通知計画の入力。SwiftData のモデルを値に写してから渡す（純粋関数としてテストするため）。
struct ItemNotificationInput: Sendable {
    var id: UUID
    var name: String
    var purchaseDate: Date
    var warrantyMonths: Int?
    var extendedMonths: Int?
    var extendedProvider: String
    var isArchived: Bool
}

/// 予約する通知1件。
struct PlannedNotification: Identifiable, Equatable, Sendable {
    var id: String
    var fireDate: Date
    var title: String
    var body: String
}

/// どの保証を、いつ、どんな文面で通知するかを決める。
enum NotificationPlanner {
    /// iOS のローカル通知の予約上限は64件。余裕を残して60件まで、発火の近い順に予約する。
    /// 遠い期限は、アプリを開くたびの組み直しで順に入る（保証期限は年単位で先なので取りこぼさない）。
    static let budget = 60

    static func plan(
        items: [ItemNotificationInput],
        settings: NotificationSettings,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [PlannedNotification] {
        let daysBefore = settings.timing.daysBefore
        guard !daysBefore.isEmpty else { return [] }

        var planned: [PlannedNotification] = []
        for item in items where !item.isArchived {
            let periods = WarrantyTerm.periods(
                purchaseDate: item.purchaseDate,
                warrantyMonths: item.warrantyMonths,
                extendedMonths: item.extendedMonths,
                calendar: calendar
            )
            for period in periods {
                for days in daysBefore {
                    guard let day = calendar.date(byAdding: .day, value: -days, to: period.lastDay),
                          let fireDate = calendar.date(
                              bySettingHour: settings.hour, minute: settings.minute, second: 0, of: day
                          ),
                          fireDate > now
                    else { continue }
                    planned.append(
                        PlannedNotification(
                            id: "warranty-\(item.id.uuidString)-\(period.kind.rawValue)-\(days)",
                            fireDate: fireDate,
                            title: String(localized: "\(item.name)の保証がまもなく終わります"),
                            body: body(item: item, period: period, daysBefore: days, calendar: calendar)
                        )
                    )
                }
            }
        }
        let sorted = planned.sorted {
            $0.fireDate == $1.fireDate ? $0.id < $1.id : $0.fireDate < $1.fireDate
        }
        return Array(sorted.prefix(budget))
    }

    /// 通知本文。**根拠を書く**（いつ買った・何年の保証か）。根拠の無い通知はオフにされる。
    static func body(
        item: ItemNotificationInput, period: WarrantyPeriod, daysBefore: Int, calendar: Calendar = .current
    ) -> String {
        let kind = period.kind == .extended && !item.extendedProvider.isEmpty
            ? String(localized: "\(period.kind.label)（\(item.extendedProvider)）")
            : period.kind.label
        let lastDay = Formatting.date(period.lastDay, calendar: calendar)
        let purchased = Formatting.date(item.purchaseDate, calendar: calendar)
        let term = Formatting.term(months: period.months)
        return String(
            localized: "\(kind)は \(lastDay) まで（あと\(daysBefore)日）。\(purchased) 購入・\(term)。気になる不具合は今のうちに相談を。"
        )
    }
}
