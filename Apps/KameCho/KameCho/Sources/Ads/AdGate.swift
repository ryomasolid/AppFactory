import AppTrackingTransparency
import GoogleMobileAds
import Observation
import StoreKit
import UIKit
import UserMessagingPlatform

/// 広告を出してよいかを、起動のたびに一度だけ確かめる（同意 → ATT → SDK 開始）。
@MainActor
@Observable
final class AdGate {
    enum Phase { case waiting, asking, ready, off }

    private(set) var phase: Phase
    private var sandbox = false

    init() {
        let args = ProcessInfo.processInfo.arguments
        // テスト・録画（-noAds）とスクショ（-sample）は広告なし。
        phase = args.contains("-noAds") || args.contains("-sample") ? .off : .waiting
    }

    func prepare() async {
        guard phase == .waiting else { return }
        phase = .asking

        let consent = UMPConsentInformation.sharedInstance
        let updated = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            consent.requestConsentInfoUpdate(with: UMPRequestParameters()) { cont.resume(returning: $0 == nil) }
        }
        if updated {
            try? await UMPConsentForm.loadAndPresentIfRequired(from: topController())
        }
        guard consent.canRequestAds else {
            phase = .off
            return
        }
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            // 起動直後だとダイアログが出ないことがあるので、少し待つ。
            try? await Task.sleep(for: .seconds(1))
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
        if case .verified(let tx)? = try? await AppTransaction.shared {
            sandbox = tx.environment == .sandbox
        }
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
    /// AdMob「KameCho Banner」（2026-11-19 作成）。
    private static let liveUnit = "ca-app-pub-6105029932689433/4935788906"

    private func topController() -> UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
        var top = root
        while let next = top?.presentedViewController { top = next }
        return top
    }
}
