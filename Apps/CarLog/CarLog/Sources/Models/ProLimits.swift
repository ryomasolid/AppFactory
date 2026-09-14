import Foundation

/// 無料版の上限。課金の線引きそのものなので、UI に散らさず1か所にまとめる。
enum ProLimits {
    /// 無料で登録できるクルマの台数。
    ///
    /// 2台目（家族のクルマ・買い替え）が購入の引き金。
    static let freeVehicles = 1

    /// 無料で登録できるメンテ項目の数。
    ///
    /// 「オイル交換／車検／自動車税」の推奨3つでちょうど埋まる。
    /// タイヤやバッテリーを足したくなった瞬間が購入のタイミングになる。
    static let freeMaintenanceItems = 3

    /// 給油・費用の記録件数と、燃費・コストの計算には**上限を置かない**。
    /// 記録が貯まらないアプリは継続も課金も生まないため。
    static let freeRecordLimit: Int? = nil

    static func canAddVehicle(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeVehicles
    }

    static func canAddMaintenanceItem(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeMaintenanceItems
    }

    /// あと何件追加できるか。Pro は nil（無制限）。
    static func remainingMaintenanceItems(currentCount: Int, isPro: Bool) -> Int? {
        isPro ? nil : max(0, freeMaintenanceItems - currentCount)
    }

    /// CSV 書き出しは Pro のみ。
    static func canExportCSV(isPro: Bool) -> Bool { isPro }
}
