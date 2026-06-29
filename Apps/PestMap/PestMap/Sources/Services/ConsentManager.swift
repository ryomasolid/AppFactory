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
        started = true

        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false

        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            guard error == nil else {
                self?.requestATTThenStartAds()
                return
            }
            UMPConsentForm.loadAndPresentIfRequired(from: Self.topViewController()) { [weak self] _ in
                self?.requestATTThenStartAds()
            }
        }
    }

    private func requestATTThenStartAds() {
        ATTrackingManager.requestTrackingAuthorization { _ in
            Self.startAds()
        }
    }

    private static func startAds() {
        DispatchQueue.main.async {
            GADMobileAds.sharedInstance().start(completionHandler: nil)
        }
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
