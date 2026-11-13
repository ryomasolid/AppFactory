import GoogleMobileAds
import Observation
import UIKit

/// 見たい人だけが見る広告（リワード広告）。クエスト達成・討伐のあとに「広告を見てボーナス」を選んだときだけ流す。
/// 旧 RN 版と同じく、最後まで見たら 50 EXP と 25 G。
@MainActor
@Observable
final class RewardedBonus: NSObject {
    static let exp = 50
    static let gold = 25

    /// Google のサンプル用（リワード）。
    static let testUnit = "ca-app-pub-3940256099942544/1712485313"
    /// AdMob「NemukeQuest Rewarded」（2026-11-13 作成）。
    static let rewardedUnit = "ca-app-pub-6105029932689433/3804079173"

    private(set) var isReady = false
    @ObservationIgnored private var ad: GADRewardedAd?
    @ObservationIgnored private var started = false
    @ObservationIgnored private var earned = false
    @ObservationIgnored private var waiting: CheckedContinuation<Bool, Never>?
    @ObservationIgnored private var unitID = RewardedBonus.testUnit

    /// 広告の手続き（同意・ATT・SDK の開始）が済んでから呼ぶ。
    func start(consent: AdConsent) async {
        guard !started, consent.phase == .ready else { return }
        started = true
        #if DEBUG
        unitID = Self.testUnit
        #else
        unitID = consent.isSandbox ? Self.testUnit : Self.rewardedUnit
        #endif
        await load()
    }

    /// 広告を流す。最後まで見てほうびの条件を満たしたら true。
    func show() async -> Bool {
        guard let ad, let presenter = Self.topViewController() else { return false }
        self.ad = nil
        isReady = false
        earned = false
        return await withCheckedContinuation { continuation in
            waiting = continuation
            ad.present(fromRootViewController: presenter) { [weak self] in
                self?.earned = true
            }
        }
    }

    private func load() async {
        do {
            let loaded = try await GADRewardedAd.load(withAdUnitID: unitID, request: GADRequest())
            loaded.fullScreenContentDelegate = self
            ad = loaded
            isReady = true
        } catch {
            // 在庫がない・電波がない。しばらくしてもう一度ためす。
            isReady = false
            try? await Task.sleep(for: .seconds(60))
            await load()
        }
    }

    private func finish() {
        waiting?.resume(returning: earned)
        waiting = nil
        Task { await load() }
    }

    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

extension RewardedBonus: GADFullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: any GADFullScreenPresentingAd) {
        MainActor.assumeIsolated { finish() }
    }

    nonisolated func ad(_ ad: any GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        MainActor.assumeIsolated { finish() }
    }
}
