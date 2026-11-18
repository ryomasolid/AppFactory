import AppTrackingTransparency
import GoogleMobileAds
import Observation
import StoreKit
import UIKit
import UserMessagingPlatform

/// 起動ごとに1回：Google の同意 → トラッキングの許可 → SDK の開始。そろったらバナーを出す。
@MainActor
@Observable
final class AdsReady {
    enum Stage { case idle, asking, ready, off }

    private(set) var stage: Stage = AdsReady.muted ? .off : .idle
    private var sandbox = false

    /// `-noAds`（テスト・録画）と `-demo`（スクショ）では出さない。
    static var muted: Bool {
        let args = ProcessInfo.processInfo.arguments
        return args.contains("-noAds") || args.contains("-demo")
    }

    func start() async {
        guard stage == .idle else { return }
        stage = .asking

        let consent = UMPConsentInformation.sharedInstance
        let updated: Bool = await withCheckedContinuation { cont in
            consent.requestConsentInfoUpdate(with: UMPRequestParameters()) { cont.resume(returning: $0 == nil) }
        }
        if updated {
            try? await UMPConsentForm.loadAndPresentIfRequired(from: Self.topController())
        }
        guard consent.canRequestAds else {
            stage = .off
            return
        }
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            // 起動直後はダイアログが出ないことがあるので少し待つ。
            try? await Task.sleep(for: .seconds(1))
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
        if let result = try? await AppTransaction.shared, case .verified(let tx) = result {
            sandbox = tx.environment == .sandbox
        }
        _ = await GADMobileAds.sharedInstance().start()
        stage = .ready
    }

    /// Debug と TestFlight では Google のテスト用ユニットを使う。
    var bannerUnit: String {
        #if DEBUG
        return Self.testUnit
        #else
        return sandbox ? Self.testUnit : Self.liveUnit
        #endif
    }

    static let testUnit = "ca-app-pub-3940256099942544/2435281174"
    /// TODO: AdMob に「ムダゼロ」を登録したら本物のバナーユニットにする。
    static let liveUnit = "ca-app-pub-3940256099942544/2435281174"

    private static func topController() -> UIViewController? {
        var vc = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        while let next = vc?.presentedViewController { vc = next }
        return vc
    }
}
