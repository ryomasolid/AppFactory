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
        case .none: return "指定なし"
        case .cockroach: return "ゴキブリ"
        case .ant: return "アリ"
        case .mosquito: return "蚊"
        case .mite: return "ダニ"
        case .other: return "その他"
        }
    }
}
