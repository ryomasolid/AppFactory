import Foundation

/// 体重の変わり方。小さな体なので、少しの減りも早めに気づけるようにする。
enum WeightTrend {
    enum Alert: Equatable {
        case dropping(percent: Int)
        case gaining(percent: Int)
    }

    struct Reading: Equatable {
        var latest: Double
        var sincePrevious: Double?
        /// 約1か月前（20〜45日前）からの変化の割合。
        var monthRatio: Double?
        var alert: Alert?
    }

    static let dropLine = -0.05
    static let gainLine = 0.10

    /// - Parameter growing: パピーは増えるのがふつうなので、増えすぎの声かけをしない。
    static func read(_ points: [(on: Date, kg: Double)], growing: Bool = false, calendar: Calendar = .current) -> Reading? {
        let sorted = points.filter { $0.kg > 0 }.sorted { $0.on < $1.on }
        guard let last = sorted.last else { return nil }
        let previous = sorted.dropLast().last
        let base = sorted.dropLast().last { point in
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: point.on), to: calendar.startOfDay(for: last.on)).day ?? 0
            return (20...45).contains(days)
        }
        let ratio = base.map { (last.kg - $0.kg) / $0.kg }
        var alert: Alert?
        if let ratio {
            if ratio <= dropLine { alert = .dropping(percent: Int((-ratio * 100).rounded())) }
            else if ratio >= gainLine, !growing { alert = .gaining(percent: Int((ratio * 100).rounded())) }
        }
        return Reading(
            latest: last.kg,
            sincePrevious: previous.map { ((last.kg - $0.kg) * 100).rounded() / 100 },
            monthRatio: ratio,
            alert: alert
        )
    }

    static func kgText(_ kg: Double) -> String {
        kg.formatted(.number.precision(.fractionLength(kg < 10 ? 2 : 1))) + "kg"
    }
}
