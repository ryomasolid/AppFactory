import Foundation

/// おせわの次の目安。
enum ChoreClock {
    struct Due: Equatable {
        var kind: ChoreKind
        var last: Date?
        var next: Date?
        var daysLeft: Int?
    }

    static func due(kind: ChoreKind, last: Date?, now: Date, calendar: Calendar = .current) -> Due {
        guard let last else { return Due(kind: kind) }
        let next = calendar.date(byAdding: .day, value: kind.everyDays, to: calendar.startOfDay(for: last))!
        let left = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: next).day ?? 0
        return Due(kind: kind, last: last, next: next, daysLeft: left)
    }
}
