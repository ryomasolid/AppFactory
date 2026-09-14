import Foundation

/// 維持費のカテゴリ。
///
/// `fuel` だけは `FuelRecord` から集計時に合成する特別枠で、
/// 費用の入力画面には出さない（`selectable` を使う）。
enum ExpenseCategory: String, CaseIterable, Identifiable, Sendable {
    case fuel
    case tax
    case insurance
    case inspection
    case maintenance
    case repairs
    case parking
    case toll
    case wash
    case parts
    case loan
    case other

    var id: String { rawValue }

    /// ユーザーが費用として手入力できるカテゴリ（ガソリン代は給油記録から自動で入るので除く）。
    static var selectable: [ExpenseCategory] { allCases.filter { $0 != .fuel } }

    var label: String {
        switch self {
        case .fuel: String(localized: "ガソリン代")
        case .tax: String(localized: "自動車税")
        case .insurance: String(localized: "保険")
        case .inspection: String(localized: "車検")
        case .maintenance: String(localized: "整備・点検")
        case .repairs: String(localized: "修理")
        case .parking: String(localized: "駐車場")
        case .toll: String(localized: "高速・有料道路")
        case .wash: String(localized: "洗車")
        case .parts: String(localized: "パーツ・用品")
        case .loan: String(localized: "ローン")
        case .other: String(localized: "その他")
        }
    }

    var symbolName: String {
        switch self {
        case .fuel: "fuelpump.fill"
        case .tax: "yensign.circle.fill"
        case .insurance: "shield.lefthalf.filled"
        case .inspection: "checkmark.seal.fill"
        case .maintenance: "wrench.and.screwdriver.fill"
        case .repairs: "hammer.fill"
        case .parking: "parkingsign.circle.fill"
        case .toll: "road.lanes"
        case .wash: "drop.fill"
        case .parts: "gearshape.2.fill"
        case .loan: "creditcard.fill"
        case .other: "ellipsis.circle.fill"
        }
    }

    /// グラフの色。アクセント1色だと内訳が読めないので、カテゴリごとに固定の色を持つ。
    var colorHex: String {
        switch self {
        case .fuel: "#0F7A80"
        case .tax: "#D1495B"
        case .insurance: "#2F7DD1"
        case .inspection: "#8E5BD1"
        case .maintenance: "#E0A21B"
        case .repairs: "#C4622D"
        case .parking: "#3E9B6B"
        case .toll: "#5B6B8C"
        case .wash: "#3FB0D1"
        case .parts: "#A3792B"
        case .loan: "#B04FA0"
        case .other: "#7A7A7A"
        }
    }
}
