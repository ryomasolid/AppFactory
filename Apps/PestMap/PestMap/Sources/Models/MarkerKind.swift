import SwiftUI

/// マーカーの種別。害虫対策の手段ごとに色とアイコンを持つ。
enum MarkerKind: String, CaseIterable, Identifiable {
    case blackCap   // ブラックキャップなどの毒餌
    case spray      // スプレー
    case fumigation // くん煙剤（バルサン等）
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .blackCap: return "ブラックキャップ"
        case .spray: return "スプレー"
        case .fumigation: return "くん煙剤"
        case .other: return "その他"
        }
    }

    var symbol: String {
        switch self {
        case .blackCap: return "ant.fill"
        case .spray: return "drop.fill"
        case .fumigation: return "smoke.fill"
        case .other: return "mappin.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .blackCap: return .red
        case .spray: return .blue
        case .fumigation: return .gray
        case .other: return .orange
        }
    }

    /// 製品ごとの標準的な交換・実施周期（プリセット）。種別選択時の初期値に使う。
    var defaultRepeat: RepeatInterval {
        switch self {
        case .blackCap: return .every3Months
        case .spray: return .monthly
        case .fumigation: return .every6Months
        case .other: return .none
        }
    }
}
