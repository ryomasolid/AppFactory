import Foundation

/// 評価のお願いは「区間を保存した」直後だけ。計算結果に納得して残した人に聞く。
/// 同じバージョンでは1回きり（アップデートするとまた1回だけ聞ける。OS 側でも年3回までに絞られる）。
struct RatingAsk {
    var defaults: UserDefaults = .standard
    var version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"

    private let askedVersionKey = "teiki.ratingAskedVersion"

    var isDue: Bool {
        if Launch.hideAds || Launch.isDemo { return false }
        return defaults.string(forKey: askedVersionKey) != version
    }

    func remember() {
        defaults.set(version, forKey: askedVersionKey)
    }
}
