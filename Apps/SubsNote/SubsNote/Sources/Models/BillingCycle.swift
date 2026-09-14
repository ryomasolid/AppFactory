import Foundation

/// 支払いの周期の単位。「3か月ごと」は `.month` と間隔 3 で表す。
enum BillingCycle: String, CaseIterable, Identifiable, Sendable {
    case week
    case month
    case year

    var id: String { rawValue }

    var label: String {
        switch self {
        case .week: String(localized: "週")
        case .month: String(localized: "月")
        case .year: String(localized: "年")
        }
    }

    /// 間隔 1 のときの1年あたりの回数。週払いは 52 回とみなす（月あたり = 金額 × 52 ÷ 12）。
    var timesPerYear: Int {
        switch self {
        case .week: 52
        case .month: 12
        case .year: 1
        }
    }

    /// 編集画面で選べる間隔の上限。
    var maxInterval: Int {
        switch self {
        case .week: 12
        case .month: 12
        case .year: 5
        }
    }
}
