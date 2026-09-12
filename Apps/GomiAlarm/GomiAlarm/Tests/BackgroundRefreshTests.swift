import Foundation
import Testing
@testable import GomiAlarm

/// バックグラウンド再構築を「いつ予約するか」の方針。
/// 予約しすぎると OS の実行枠を無駄に食い、遅すぎると通知の窓が枯れて鳴らなくなる。
struct BackgroundRefreshTests {

    private let now = at(2026, 9, 1, 9)

    private func result(
        authorized: Bool = true,
        isPermanent: Bool = false,
        coveredThrough: Date? = nil,
        scheduled: Int = 10
    ) -> NotificationScheduler.RebuildResult {
        NotificationScheduler.RebuildResult(
            authorized: authorized, scheduled: scheduled, failed: 0,
            isPermanent: isPermanent, coveredThrough: coveredThrough, truncated: false
        )
    }

    @Test func permanentPlanNeedsNoBackgroundRefresh() {
        // 毎週くり返しだけで組めていれば期限が無いので、実行枠を取らない。
        let date = BackgroundRefreshPolicy.nextRefreshDate(
            for: result(isPermanent: true, coveredThrough: nil), now: now
        )
        #expect(date == nil)
    }

    @Test func unauthorizedNeedsNoBackgroundRefresh() {
        // 未許可なら組み直しても登録できない。許可後はフォアグラウンド復帰時に組み直す。
        let date = BackgroundRefreshPolicy.nextRefreshDate(
            for: result(authorized: false, coveredThrough: day(2026, 11, 1)), now: now
        )
        #expect(date == nil)
    }

    @Test func refreshesAtHalfOfTheCoveredSpan() {
        // 10日ぶんカバーできていれば5日後。実行が遅れても残り半分は生きている。
        let date = BackgroundRefreshPolicy.nextRefreshDate(
            for: result(coveredThrough: now.addingTimeInterval(10 * 24 * 3600)), now: now
        )
        #expect(date == now.addingTimeInterval(5 * 24 * 3600))
    }

    @Test func longSpanIsCappedAtOneWeek() {
        // 120日ぶん登録できていても、最低でも週1回は組み直す。
        let date = BackgroundRefreshPolicy.nextRefreshDate(
            for: result(coveredThrough: now.addingTimeInterval(120 * 24 * 3600)), now: now
        )
        #expect(date == now.addingTimeInterval(BackgroundRefreshPolicy.maximumDelay))
    }

    @Test func shortSpanIsFlooredAtOneDay() {
        // 残りわずかでも1日より短くは予約しない（短く出しても OS に間引かれるだけ）。
        let date = BackgroundRefreshPolicy.nextRefreshDate(
            for: result(coveredThrough: now.addingTimeInterval(6 * 3600)), now: now
        )
        #expect(date == now.addingTimeInterval(BackgroundRefreshPolicy.minimumDelay))
    }

    @Test func noCoverageFallsBackToMaximumDelay() {
        // 収集日が1件も無い（種類未登録など）ときは、最長間隔で様子を見る。
        let date = BackgroundRefreshPolicy.nextRefreshDate(for: result(coveredThrough: nil), now: now)
        #expect(date == now.addingTimeInterval(BackgroundRefreshPolicy.maximumDelay))
    }
}
