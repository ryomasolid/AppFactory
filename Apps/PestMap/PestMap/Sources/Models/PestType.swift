import Foundation

/// 対象の害虫の種類タグ。
enum PestType: String, CaseIterable, Identifiable {
    case none
    case cockroach
    case ant
    case mosquito
    case mite
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return String(localized: "指定なし")
        case .cockroach: return String(localized: "ゴキブリ")
        case .ant: return String(localized: "アリ")
        case .mosquito: return String(localized: "蚊")
        case .mite: return String(localized: "ダニ")
        case .other: return String(localized: "その他")
        }
    }
}
