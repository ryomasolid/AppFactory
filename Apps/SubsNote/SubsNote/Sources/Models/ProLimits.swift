import Foundation

/// 無料版の上限。課金の線引きそのものなので、UI に散らさず1か所にまとめる。
enum ProLimits {
    /// 無料で登録できるサブスクの数。
    ///
    /// 日本の平均契約数は3〜5件なので、6件目を登録したくなった瞬間が購入のタイミングになる。
    /// **解約済みは数えない**（解約を記録するほど損をする作りにしない）。その代わり再開するときに上限を確認する。
    static let freeSubscriptions = 5

    /// 通知と、合計・カレンダーは**無料で使える**。
    /// ここを塞ぐと「解約し忘れを防ぐ」という価値が伝わる前に離脱する。
    static let isNotificationFree = true
    static let isTotalFree = true

    /// 上限に数える件数（解約済みを除く）。
    static func countedSubscriptions(isCancelled: [Bool]) -> Int {
        isCancelled.filter { !$0 }.count
    }

    /// 追加（または解約済みの再開）ができるか。
    static func canAdd(activeCount: Int, isPro: Bool) -> Bool {
        isPro || activeCount < freeSubscriptions
    }

    /// あと何件追加できるか。Pro は nil（無制限）。
    static func remaining(activeCount: Int, isPro: Bool) -> Int? {
        isPro ? nil : max(0, freeSubscriptions - activeCount)
    }

    /// カテゴリ別・支払い方法別の内訳は Pro のみ。
    static func canSeeBreakdown(isPro: Bool) -> Bool { isPro }

    /// CSV 書き出しは Pro のみ。
    static func canExport(isPro: Bool) -> Bool { isPro }
}
