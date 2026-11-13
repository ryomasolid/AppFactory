import Foundation

/// App Store の評価をお願いするタイミング。
///
/// 「出した」に印をつけて、連続回数が 5 回以上になった人＝毎週ちゃんと使えている人にだけ聞く。
/// 聞いたら 100 日はあける（OS 側も年3回までに絞る）。
enum RatingPrompt {
    static let minimumStreak = 5
    static let quietDays = 100
    private static let lastAskedKey = "ga.ratingAskedAt"

    static func shouldAsk(streak: Int, now: Date = Date(), defaults: UserDefaults = .standard) -> Bool {
        guard !Launch.hideAds, !Launch.isDemo else { return false }
        guard streak >= minimumStreak else { return false }
        guard let last = defaults.object(forKey: lastAskedKey) as? Date else { return true }
        return now.timeIntervalSince(last) >= Double(quietDays) * 86_400
    }

    static func markAsked(now: Date = Date(), defaults: UserDefaults = .standard) {
        defaults.set(now, forKey: lastAskedKey)
    }
}
