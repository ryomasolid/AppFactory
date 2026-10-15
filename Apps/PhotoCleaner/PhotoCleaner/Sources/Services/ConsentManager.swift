import AppTrackingTransparency
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

/// 広告の同意フローを管理する。
/// ATT（トラッキング許可）→ UMP（GDPR等の同意）→ AdMob 初期化、の順で1回だけ実行する。
///
/// ATT を先にするのは、UMP の通信（数秒かかることがある）を待つと許可ダイアログが遅れて、
/// 写真の許可など別の画面と重なり、見落とされたり出なかったりするため（審査 2.1 で指摘された）。
/// どちらの場合も広告 SDK は ATT に答えたあとに始めるので、答える前にトラッキングのデータは集めない。
@MainActor
final class ConsentManager {
    static let shared = ConsentManager()
    private var started = false

    func start() {
        guard !started else { return }
        started = true

        Task { @MainActor in
            await Self.requestTrackingWhenActive()
            Self.updateConsentThenStartAds()
        }
    }

    /// ATT はアプリが前面（active）のときにしか出ず、それ以外で呼ぶと何も表示せずに「未決定」のまま返る。
    /// 写真の許可ダイアログが出ている間なども inactive になるので、active に戻るまで待ってから呼ぶ。
    /// それでも出なかった（未決定のまま返った）ときは、もう一度だけ待ち直して呼ぶ。
    private static func requestTrackingWhenActive() async {
        for _ in 0..<2 {
            guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
            while UIApplication.shared.applicationState != .active {
                try? await Task.sleep(for: .milliseconds(200))
            }
            // 「はじめる」で画面が切り替わる途中に重ならないよう、少しだけ待つ。
            try? await Task.sleep(for: .milliseconds(500))
            guard UIApplication.shared.applicationState == .active else { continue }
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
    }

    private static func updateConsentThenStartAds() {
        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false

        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { error in
            guard error == nil else {
                startAds()
                return
            }
            UMPConsentForm.loadAndPresentIfRequired(from: topViewController()) { _ in
                startAds()
            }
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
