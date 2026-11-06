import Foundation
import SwiftData

/// 新しく登録した品物が3つ目以上になったら、App Store の評価をお願いする。
/// 前回お願いしたときより品物が5つ以上ふえていなければ、もう聞かない（しつこくしない）。
enum StoreRating {
    private static let countKey = "wp.ratingAskedAtItemCount"

    @MainActor
    static func wantsToAsk(after context: ModelContext, defaults: UserDefaults = .standard) -> Bool {
        if Launch.hideAds || Launch.isDemo { return false }
        let items = (try? context.fetchCount(FetchDescriptor<Item>())) ?? 0
        guard items >= 3 else { return false }
        let askedAt = defaults.integer(forKey: countKey)
        guard askedAt == 0 || items >= askedAt + 5 else { return false }
        defaults.set(items, forKey: countKey)
        return true
    }
}
