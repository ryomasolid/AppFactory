import Foundation

/// めだかの卵は「水温 × 日数」がおよそ 250 になると孵る（25℃ なら 10 日、20℃ なら 12〜13 日）。
enum HatchClock {
    static let degreeDays: Double = 250
    /// これより低いと発生がほぼ止まる。
    static let coldLimit: Double = 15

    /// 孵るまでの日数。冷たすぎれば nil。
    static func daysToHatch(celsius: Double) -> Int? {
        guard celsius >= coldLimit else { return nil }
        return Int((degreeDays / celsius).rounded(.up))
    }

    static func expectedDay(collectedOn: Date, celsius: Double, calendar: Calendar = .current) -> Date? {
        guard let days = daysToHatch(celsius: celsius) else { return nil }
        return calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: collectedOn))
    }

    /// 0〜1 の進み具合（積算温度ベース）。
    static func progress(collectedOn: Date, celsius: Double, now: Date, calendar: Calendar = .current) -> Double {
        let elapsed = elapsedDays(since: collectedOn, now: now, calendar: calendar)
        guard celsius >= coldLimit else { return 0 }
        return min(1, Double(elapsed) * celsius / degreeDays)
    }

    static func elapsedDays(since start: Date, now: Date, calendar: Calendar = .current) -> Int {
        max(0, calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: now)).day ?? 0)
    }

    /// 孵化率（%）。卵0個なら nil。
    static func hatchRate(eggs: Int, hatched: Int) -> Int? {
        guard eggs > 0 else { return nil }
        return Int((Double(hatched) / Double(eggs) * 100).rounded())
    }
}
