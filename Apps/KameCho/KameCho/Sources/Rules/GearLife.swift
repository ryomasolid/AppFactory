import Foundation

/// 器具の交換までの残り。
enum GearLife {
    static func dueDate(installedOn: Date, lifeDays: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: lifeDays, to: calendar.startOfDay(for: installedOn)) ?? installedOn
    }

    /// 残りの日数（すぎていれば負）。
    static func daysLeft(installedOn: Date, lifeDays: Int, now: Date, calendar: Calendar = .current) -> Int {
        let due = dueDate(installedOn: installedOn, lifeDays: lifeDays, calendar: calendar)
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: due).day ?? 0
    }

    /// 使った割合（0〜1）。
    static func used(installedOn: Date, lifeDays: Int, now: Date, calendar: Calendar = .current) -> Double {
        guard lifeDays > 0 else { return 1 }
        let left = daysLeft(installedOn: installedOn, lifeDays: lifeDays, now: now, calendar: calendar)
        return min(1, max(0, 1 - Double(left) / Double(lifeDays)))
    }

    /// 2週間前から「そろそろ」。
    static func soon(daysLeft: Int) -> Bool { daysLeft <= 14 }
}
