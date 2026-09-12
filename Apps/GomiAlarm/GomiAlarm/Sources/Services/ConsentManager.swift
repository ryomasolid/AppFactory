import AppTrackingTransparency
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

/// 広告の同意フローを管理する。
/// UMP（GDPR等の同意）→ ATT（トラッキング許可）→ AdMob 初期化、の順で1回だけ実行する。
@MainActor
final class ConsentManager {
    static let shared = ConsentManager()
    private var started = false

    func start() {
        guard !started else { return }
        // 広告非表示（スクショ撮影）時は同意・ATT フローを一切走らせない。
        guard !Launch.hideAds else { return }
        started = true

        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false

        // UMP / ATT のコールバックは非分離（任意のスレッド）で呼ばれるので、
        // MainActor に戻してから UI とこのクラスの状態に触る。
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            let didFail = error != nil
            Task { @MainActor in
                // 同意フォームの表示に失敗しても、ATT と広告初期化は続ける
                // （同意が不要な地域では何も表示されずに返る）。
                if !didFail {
                    try? await UMPConsentForm.loadAndPresentIfRequired(from: Self.topViewController())
                }
                self?.requestATTThenStartAds()
            }
        }
    }

    private func requestATTThenStartAds() {
        Task { @MainActor in
            _ = await ATTrackingManager.requestTrackingAuthorization()
            Self.startAds()
        }
    }

    @MainActor
    private static func startAds() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
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
