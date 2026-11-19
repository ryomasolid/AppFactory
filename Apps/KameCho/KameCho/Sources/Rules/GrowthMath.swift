import Foundation

/// 甲長・体重の伸び。
enum GrowthMath {
    struct Point: Equatable {
        let on: Date
        let value: Double
    }

    /// 直前の計測からの差。
    static func change(_ points: [Point]) -> Double? {
        let sorted = points.sorted { $0.on < $1.on }
        guard sorted.count >= 2 else { return nil }
        return sorted[sorted.count - 1].value - sorted[sorted.count - 2].value
    }

    /// 1年あたりの伸び。2か月以上あいた計測が2つ以上あるときだけ（最近1年ぶんで見る）。
    static func perYear(_ points: [Point], now: Date, calendar: Calendar = .current) -> Double? {
        let sorted = points.sorted { $0.on < $1.on }
        guard let last = sorted.last else { return nil }
        let yearAgo = calendar.date(byAdding: .day, value: -365, to: last.on) ?? last.on
        let first = sorted.last { $0.on <= yearAgo } ?? sorted.first!
        let days = Double(calendar.dateComponents([.day], from: first.on, to: last.on).day ?? 0)
        guard days >= 60 else { return nil }
        return (last.value - first.value) / days * 365
    }

    static func shell(_ measures: [Measure]) -> [Point] {
        measures.compactMap { m in m.shellMM.map { Point(on: m.on, value: $0) } }
    }

    static func weight(_ measures: [Measure]) -> [Point] {
        measures.compactMap { m in m.grams.map { Point(on: m.on, value: $0) } }
    }
}
