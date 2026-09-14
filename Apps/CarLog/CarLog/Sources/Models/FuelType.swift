import Foundation

/// 燃料の種別。単価の目安表示と、EV のときに「燃費」を「電費」と呼び替えるために持つ。
enum FuelType: String, CaseIterable, Identifiable, Sendable {
    case regular
    case highOctane
    case diesel
    case electric

    var id: String { rawValue }

    var label: String {
        switch self {
        case .regular: String(localized: "レギュラー")
        case .highOctane: String(localized: "ハイオク")
        case .diesel: String(localized: "軽油")
        case .electric: String(localized: "電気")
        }
    }

    /// 給油量の単位。EV だけ kWh になる。
    var volumeUnit: String {
        self == .electric ? String(localized: "kWh") : String(localized: "L")
    }

    /// 燃費の単位。
    var economyUnit: String {
        self == .electric ? String(localized: "km/kWh") : String(localized: "km/L")
    }

    /// 「給油」という語も EV では通じないので呼び替える。
    var refuelLabel: String {
        self == .electric ? String(localized: "充電") : String(localized: "給油")
    }
}
