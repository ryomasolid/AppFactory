import Foundation

/// 温度の目安（℃）。
enum Heat {
    enum Verdict: Equatable {
        case low, ok, high
    }

    struct Band: Equatable {
        let base: ClosedRange<Double>
        let spot: ClosedRange<Double>
    }

    static func band(for species: Species) -> Band {
        switch species.habitat {
        case .water: Band(base: 24...28, spot: 30...35)
        case .land: species.tropical ? Band(base: 25...30, spot: 33...40) : Band(base: 22...28, spot: 32...38)
        }
    }

    static func judge(_ value: Double, in range: ClosedRange<Double>) -> Verdict {
        value < range.lowerBound ? .low : value > range.upperBound ? .high : .ok
    }

    static func baseName(_ habitat: Habitat) -> String { habitat == .water ? "水温" : "ケージ" }
    static func spotName(_ habitat: Habitat) -> String { habitat == .water ? "バスキング" : "ホットスポット" }
}
