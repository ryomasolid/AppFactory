import GoogleMobileAds
import UIKit
import UserMessagingPlatform

/// 見たい人だけが見る広告（リワード広告）。宿屋と 全滅のあとで 選んだときだけ流す。
/// バナーや 場面の切りかえで 勝手に出る広告は 入れない。
///
/// 小学生も遊ぶので、子ども向けとして リクエストする（パーソナライズなし・一般向けの広告だけ）。
/// トラッキングはしないので ATT の許可も求めない。
@MainActor
final class RewardAds: NSObject {
    #if DEBUG
    // Google の テスト用 ユニット。開発中に 本番の広告を 押してしまわないように。
    private static let unitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    private static let unitID = "ca-app-pub-6105029932689433/REPLACE_ME"
    #endif

    /// 読み込みが済んだか 変わったときに 知らせる（GameState の 選択肢を 出し分ける）。
    var onReadyChange: (Bool) -> Void = { _ in }

    private var ad: RewardedAd?
    private var started = false
    private var rewarded = false
    private var waiting: CheckedContinuation<Bool, Never>?

    func start() async {
        guard !started else { return }
        started = true

        // EU などで 同意が いる地域向け。子どもとして扱うので 同意フォームは 出ない。
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = true
        try? await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
        guard ConsentInformation.shared.canRequestAds else { return }

        let configuration = MobileAds.shared.requestConfiguration
        configuration.tagForChildDirectedTreatment = true
        configuration.tagForUnderAgeOfConsent = true
        configuration.maxAdContentRating = .general
        await MobileAds.shared.start()
        await load()
    }

    /// 広告を流す。最後まで見て ほうびの条件を みたしたら true。
    func show() async -> Bool {
        guard let ad, let presenter = Self.topViewController() else { return false }
        self.ad = nil
        onReadyChange(false)
        rewarded = false
        return await withCheckedContinuation { continuation in
            waiting = continuation
            ad.present(from: presenter) { [weak self] in
                self?.rewarded = true
            }
        }
    }

    private func load() async {
        do {
            let loaded = try await RewardedAd.load(with: Self.unitID, request: Request())
            loaded.fullScreenContentDelegate = self
            ad = loaded
            onReadyChange(true)
        } catch {
            // 在庫がない・電波がない。しばらくして もう一度 ためす。
            onReadyChange(false)
            try? await Task.sleep(for: .seconds(60))
            await load()
        }
    }

    private func finish() {
        waiting?.resume(returning: rewarded)
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

extension RewardAds: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        MainActor.assumeIsolated { finish() }
    }

    nonisolated func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        MainActor.assumeIsolated { finish() }
    }
}
