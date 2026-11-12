import Foundation

/// 容器1つの「いまどうなっているか」をまとめたもの。画面と通知の両方で使う。
struct VesselState {
    let lastWaterChange: Date?
    let waterInterval: Int
    /// 次の水換えの目安日（記録がなければ立ち上げ日から数える）。
    let waterDue: Date
    let lastFeed: Date?
    let celsius: Double?
    let mood: WaterSense.Mood?
    let crowded: Bool
    /// 直近30日に★になった数。
    let recentLosses: Int

    init(vessel: Vessel, now: Date = Date(), calendar: Calendar = .current) {
        let temp = vessel.lastTemperature
        // 1週間より前の水温は季節が変わっているかもしれないので、目安には使わない。
        let freshTemp = temp.flatMap { calendar.dateComponents([.day], from: $0.at, to: now).day ?? 99 <= 7 ? $0.celsius : nil }
        celsius = temp?.celsius
        mood = freshTemp.map(WaterSense.mood(celsius:))
        lastWaterChange = vessel.latest(.waterChange)?.at
        lastFeed = vessel.latest(.feed)?.at
        waterInterval = WaterSense.waterChangeInterval(liters: vessel.liters, headcount: vessel.headcount, outdoors: vessel.outdoors, celsius: freshTemp)
        let base = calendar.startOfDay(for: lastWaterChange ?? vessel.setUpOn)
        waterDue = calendar.date(byAdding: .day, value: waterInterval, to: base) ?? base
        crowded = WaterSense.isCrowded(liters: vessel.liters, headcount: vessel.headcount, stage: vessel.stage)
        let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        recentLosses = (vessel.logs ?? []).filter { $0.kind == .loss && $0.at >= monthAgo }.reduce(0) { $0 + ($1.count ?? 0) }
    }

    /// 今日を0として、水換えの目安まであと何日か（過ぎていれば負）。
    func daysUntilWater(now: Date = Date(), calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: waterDue).day ?? 0
    }
}
