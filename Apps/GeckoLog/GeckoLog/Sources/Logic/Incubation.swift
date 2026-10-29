import Foundation

/// レオパの卵の温度と孵化日数・性別の傾向（温度依存性決定）。
/// 数値は国内外の飼育書でよく使われる目安で、個体差・環境差が大きい。画面にも「目安」と出す。
enum Incubation {
    /// 温度(℃) → 孵化までのおよその日数。
    private static let daysByTemperature: [(c: Double, days: Double)] = [
        (26, 65), (27, 58), (28, 53), (29, 49), (30, 45), (31, 42), (32, 40), (33, 38),
    ]

    static let supportedRange: ClosedRange<Double> = 24...34

    static func expectedDays(at celsius: Double) -> Int {
        let table = daysByTemperature
        if celsius <= table.first!.c { return Int(table.first!.days) }
        if celsius >= table.last!.c { return Int(table.last!.days) }
        for (low, high) in zip(table, table.dropFirst()) where celsius <= high.c {
            let ratio = (celsius - low.c) / (high.c - low.c)
            return Int((low.days + (high.days - low.days) * ratio).rounded())
        }
        return Int(table.last!.days)
    }

    static func expectedHatchDay(laidOn: Date, celsius: Double, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: expectedDays(at: celsius), to: calendar.startOfDay(for: laidOn)) ?? laidOn
    }

    static func sexTendency(at celsius: Double) -> String {
        switch celsius {
        case ..<26: "低すぎるかも（孵化しにくい）"
        case ..<29.5: "メスが多め"
        case ..<31: "オス・メスが混ざる"
        case ..<33: "オスが多め"
        default: "高すぎるかも（メス寄り・弱い子が出やすい）"
        }
    }
}

extension Clutch {
    var expectedHatchDay: Date { Incubation.expectedHatchDay(laidOn: laidOn, celsius: incubationC) }
}
