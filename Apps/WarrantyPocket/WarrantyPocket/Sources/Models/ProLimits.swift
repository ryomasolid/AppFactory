import Foundation

/// 無料版の上限。課金の線引きそのものなので、UI に散らさず1か所にまとめる。
enum ProLimits {
    /// 無料で登録できる商品の数。
    ///
    /// 一家の家電は20〜30点あるので、11件目を登録したくなった瞬間が購入のタイミングになる。
    /// 手放した（アーカイブした）商品も数える。数えないと「アーカイブして追加」で無限に使える。
    static let freeItems = 10

    /// 写真の読み取りと期限の通知は**無料で使える**。
    /// ここを塞ぐと「撮るだけ」「知らせてくれる」という価値が伝わる前に離脱する。
    static let isReadingFree = true
    static let isNotificationFree = true

    static func canAddItem(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeItems
    }

    /// あと何件追加できるか。Pro は nil（無制限）。
    static func remainingItems(currentCount: Int, isPro: Bool) -> Int? {
        isPro ? nil : max(0, freeItems - currentCount)
    }

    /// PDF・CSV の書き出しは Pro のみ。
    static func canExport(isPro: Bool) -> Bool { isPro }
}
