import Foundation

/// 室温の目安。セキセイインコは寒さに弱く、ヒナ・病気のときはさらに暖かくする。
enum Warmth {
    enum Verdict: Equatable {
        case cold, chilly, good, warm, hot

        var label: String {
            switch self {
            case .cold: "寒すぎ"
            case .chilly: "すこし寒い"
            case .good: "ちょうどいい"
            case .warm: "すこし暑い"
            case .hot: "暑すぎ"
            }
        }

        var needsCare: Bool { self != .good }
    }

    /// - Parameter young: 生後6か月まで（ヒナ・若鳥）。
    static func verdict(celsius: Double, young: Bool = false) -> Verdict {
        let low: Double = young ? 25 : 20
        if celsius < low - 5 { return .cold }
        if celsius < low { return .chilly }
        if celsius < 29 { return .good }
        if celsius < 32 { return .warm }
        return .hot
    }

    static func isYoung(hatchedOn: Date?, now: Date, calendar: Calendar = .current) -> Bool {
        guard let hatchedOn else { return false }
        let months = calendar.dateComponents([.month], from: hatchedOn, to: now).month ?? 0
        return months < 6
    }

    static func ageText(hatchedOn: Date, now: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month], from: calendar.startOfDay(for: hatchedOn), to: calendar.startOfDay(for: now))
        let y = max(parts.year ?? 0, 0), m = max(parts.month ?? 0, 0)
        if y == 0 { return m == 0 ? "生まれたて" : "\(m)か月" }
        return m == 0 ? "\(y)さい" : "\(y)さい\(m)か月"
    }
}
