import Foundation

/// 麺とご飯の換算。基準は日本食品標準成分表（八訂）。茶碗とラーメン1杯は比較用の目安で、サイトの早見表と同じ値。
enum Portions {
    static let noodleBoilRatio = 1.9
    static let noodleKcalPer100g = 249.0
    static let riceKcalPer100g = 156.0
    static let bowlGrams = 150.0
    static let ramenNoodleGrams = 150.0
    /// 茶碗1杯のご飯のカロリー。記録を「茶碗何杯ぶん」に言い換えるときに使う。
    static var bowlKcal: Double { bowlGrams * riceKcalPer100g / 100 }

    struct Noodle: Equatable {
        let raw: Double
        let boiled: Double
        var kcal: Double { raw * noodleKcalPer100g / 100 }
        var ramenCount: Double { raw / ramenNoodleGrams }
    }

    static func noodle(grams: Double, isBoiledFigure: Bool) -> Noodle {
        isBoiledFigure
            ? Noodle(raw: grams / noodleBoilRatio, boiled: grams)
            : Noodle(raw: grams, boiled: grams * noodleBoilRatio)
    }

    static func riceBowls(grams: Double) -> Double { grams / bowlGrams }
    static func riceKcal(grams: Double) -> Double { grams * riceKcalPer100g / 100 }
}
