import AppTrackingTransparency
import GoogleMobileAds
import Observation
import StoreKit
import UIKit
import UserMessagingPlatform

/// 広告を出してよいかを、起動ごとに1回たしかめる：同意（UMP）→ トラッキングの許可（ATT）→ SDK を起こす。
@MainActor
@Observable
final class AdGate {
    enum State { case waiting, asking, open, closed }

    /// `-calm`（テスト・審査用の録画）・`-sample`（スクショ）では広告を出さない。
    static var mutedByArguments: Bool {
        let args = ProcessInfo.processInfo.arguments
        return args.contains("-calm") || args.contains("-sample")
    }

    private(set) var state: State = AdGate.mutedByArguments ? .closed : .waiting
    /// TestFlight（sandbox）ではテスト広告にする。
    private(set) var inSandbox = false

    func prepare() async {
        guard state == .waiting else { return }
        state = .asking

        let consent = UMPConsentInformation.sharedInstance
        let refreshed = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            consent.requestConsentInfoUpdate(with: UMPRequestParameters()) { cont.resume(returning: $0 == nil) }
        }
        if refreshed, let host = Self.topScreen() {
            try? await UMPConsentForm.loadAndPresentIfRequired(from: host)
        }
        guard consent.canRequestAds else {
            state = .closed
            return
        }

        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            // 起動したてだとダイアログが出ないことがあるので、少し待つ。
            try? await Task.sleep(for: .milliseconds(900))
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }

        if case .verified(let transaction)? = try? await AppTransaction.shared {
            inSandbox = transaction.environment == .sandbox
        }
        _ = await GADMobileAds.sharedInstance().start()
        state = .open
    }

    var bannerID: String {
        #if DEBUG
        Self.sampleBanner
        #else
        inSandbox ? Self.sampleBanner : Self.liveBanner
        #endif
    }

    /// Google のサンプル（アダプティブバナー）。
    static let sampleBanner = "ca-app-pub-3940256099942544/2435281174"
    /// AdMob「ToypooDiary Banner」（2026-11-16 作成）。
    static let liveBanner = "ca-app-pub-6105029932689433/4644985181"

    private static func topScreen() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        var top = scenes.flatMap(\.windows).first { $0.isKeyWindow }?.rootViewController
        while let next = top?.presentedViewController { top = next }
        return top
    }
}
