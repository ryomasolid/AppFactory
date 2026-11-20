import GoogleMobileAds
import Observation
import StoreKit
import UserMessagingPlatform

/// 広告を出してよいかを、起動のたびに一度だけ確かめて SDK を始める。
/// 子どもも使う学習アプリなので、子ども向けとしてリクエストする（ATT は出さない・同意フォームも出ない）。
@MainActor
@Observable
final class AdGate {
    enum Phase { case waiting, asking, ready, off }

    private(set) var phase: Phase
    private var sandbox = false

    init() {
        let args = ProcessInfo.processInfo.arguments
        // テスト・録画（-noAds）とスクショ（-demo）は広告なし。
        phase = args.contains("-noAds") || args.contains("-demo") ? .off : .waiting
    }

    func prepare() async {
        guard phase == .waiting else { return }
        phase = .asking

        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = true
        let consent = UMPConsentInformation.sharedInstance
        _ = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            consent.requestConsentInfoUpdate(with: parameters) { cont.resume(returning: $0 == nil) }
        }
        guard consent.canRequestAds else {
            phase = .off
            return
        }
        if case .verified(let tx)? = try? await AppTransaction.shared {
            sandbox = tx.environment == .sandbox
        }
        let config = GADMobileAds.sharedInstance().requestConfiguration
        config.tagForChildDirectedTreatment = true
        config.tagForUnderAgeOfConsent = true
        config.maxAdContentRating = .general
        _ = await GADMobileAds.sharedInstance().start()
        phase = .ready
    }

    /// Debug と TestFlight は Google のテスト用ユニットを使う。
    var unitID: String {
        #if DEBUG
        Self.testUnit
        #else
        sandbox ? Self.testUnit : Self.liveUnit
        #endif
    }

    private static let testUnit = "ca-app-pub-3940256099942544/2435281174"
    /// AdMob「KokkiShuto Banner」（2026-11-20 作成）。
    private static let liveUnit = "ca-app-pub-6105029932689433/4371404436"
}
