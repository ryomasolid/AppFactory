import Foundation
import Testing
@testable import GomiAlarm

/// 無料版の上限。課金の線引きそのものなので、境界をテストで固定する。
struct ProLimitsTests {

    @Test func freeUserCanAddUpToTheLimit() {
        #expect(ProLimits.canAddKind(currentCount: 0, isPro: false))
        #expect(ProLimits.canAddKind(currentCount: ProLimits.freeKinds - 1, isPro: false))
    }

    @Test func freeUserIsBlockedAtTheLimit() {
        // ちょうど上限に達したら、次の追加で課金画面に誘導する。
        #expect(!ProLimits.canAddKind(currentCount: ProLimits.freeKinds, isPro: false))
        #expect(!ProLimits.canAddKind(currentCount: ProLimits.freeKinds + 1, isPro: false))
    }

    @Test func proUserIsNeverBlocked() {
        #expect(ProLimits.canAddKind(currentCount: ProLimits.freeKinds, isPro: true))
        #expect(ProLimits.canAddKind(currentCount: 100, isPro: true))
    }

    @Test func remainingCountsDownToZero() {
        #expect(ProLimits.remainingKinds(currentCount: 0, isPro: false) == ProLimits.freeKinds)
        #expect(ProLimits.remainingKinds(currentCount: ProLimits.freeKinds, isPro: false) == 0)
        // デモデータのように上限を超えて持っていても、負の数を出さない。
        #expect(ProLimits.remainingKinds(currentCount: ProLimits.freeKinds + 5, isPro: false) == 0)
    }

    @Test func proHasNoRemainingLimit() {
        #expect(ProLimits.remainingKinds(currentCount: 10, isPro: true) == nil)
    }

    @Test func freeLimitMatchesTheTypicalStartingSet() {
        // 「燃えるゴミ／資源／プラ」でちょうど埋まる数であること（課金動機の設計）。
        #expect(ProLimits.freeKinds == 3)
    }
}
