import Foundation

/// 無料版の上限。課金の線引きそのものなので、UI に散らさず1か所にまとめる。
enum ProLimits {
    /// 無料で登録できるゴミの種類の数。
    ///
    /// 「燃えるゴミ／資源／プラ」でちょうど埋まる数にしてある。
    /// 缶・瓶や粗大ごみを足したくなった瞬間が購入のタイミングになる。
    /// 収集の周期（隔週・第n曜日など）は**無料で全部使える**。
    /// そこを塞ぐと実用にならず、離脱するだけで購入には繋がらない。
    static let freeKinds = 3

    static func canAddKind(currentCount: Int, isPro: Bool) -> Bool {
        isPro || currentCount < freeKinds
    }

    /// あと何種類登録できるか。Pro は nil（無制限）。
    static func remainingKinds(currentCount: Int, isPro: Bool) -> Int? {
        isPro ? nil : max(0, freeKinds - currentCount)
    }
}
