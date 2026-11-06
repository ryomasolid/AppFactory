import Foundation

/// App Store の評価をお願いするタイミング。
///
/// 燃費は満タン給油が2回そろって初めて出るので、「給油を新しく3件以上つけた」＝
/// 燃費の数字が見えている人にだけ聞く。聞いたら 120 日はあける（OS 側も年3回までに絞る）。
enum ReviewMoment {
    static let minimumFuelRecords = 3
    static let quietDays = 120
    private static let lastAskedKey = "cl.reviewAskedAt"

    static func shouldAsk(fuelRecordCount: Int, now: Date = Date(), defaults: UserDefaults = .standard) -> Bool {
        guard !Launch.hideAds, !Launch.isDemo else { return false }
        guard fuelRecordCount >= minimumFuelRecords else { return false }
        guard let last = defaults.object(forKey: lastAskedKey) as? Date else { return true }
        return now.timeIntervalSince(last) >= Double(quietDays) * 86_400
    }

    static func markAsked(now: Date = Date(), defaults: UserDefaults = .standard) {
        defaults.set(now, forKey: lastAskedKey)
    }
}
