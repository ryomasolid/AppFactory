import Foundation
import SwiftData

/// 「実施した」を2回以上つけた人＝通知で戻ってきて対策を続けている人にだけ、評価をお願いする。
/// 一度聞いたら 90 日はあける。
@MainActor
enum ReviewTiming {
    private static let key = "pestmap.reviewRequestedOn"
    private static let gap: TimeInterval = 90 * 24 * 60 * 60

    static func isRightAfterDone(in context: ModelContext, now: Date = .now) -> Bool {
        if ProcessInfo.processInfo.arguments.contains("-hideAds") { return false }
        let doneCount = (try? context.fetchCount(FetchDescriptor<DoneRecord>())) ?? 0
        guard doneCount >= 2 else { return false }
        if let last = UserDefaults.standard.object(forKey: key) as? Date, now.timeIntervalSince(last) < gap {
            return false
        }
        UserDefaults.standard.set(now, forKey: key)
        return true
    }
}
