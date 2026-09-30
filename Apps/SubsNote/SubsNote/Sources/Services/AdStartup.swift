import AppTrackingTransparency
import GoogleMobileAds
import UIKit
import UserMessagingPlatform

/// 広告を出す前の手続き。起動ごとに1回、次の順で進める。
///
/// 1. 同意情報を更新し、必要な地域なら同意フォームを出す（UMP）
/// 2. 広告を出してよい状態なら、トラッキングの許可を尋ねる（ATT）
/// 3. AdMob を初期化する
///
/// 同意が得られない地域では 2 と 3 を飛ばす（その場合バナーは空のまま閉じる）。
@MainActor
enum AdStartup {
    private static var hasRun = false

    static func runOnce() {
        // スクショ撮影（-hideAds）と Pro ではダイアログを一切出さない。
        guard !hasRun, !Launch.hideAds, !UserDefaults.standard.bool(forKey: "sn.proUnlocked") else { return }
        hasRun = true
        Task { await proceed() }
    }

    private static func proceed() async {
        await refreshConsent()
        let consent = UMPConsentInformation.sharedInstance
        guard consent.canRequestAds else { return }
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
        _ = await GADMobileAds.sharedInstance().start()
    }

    /// 同意情報の更新と、必要なときだけフォームの表示。失敗しても先に進む（前回の同意が残っていれば広告は出せる）。
    private static func refreshConsent() async {
        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false
        let updated = await withCheckedContinuation { continuation in
            UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: parameters) { error in
                continuation.resume(returning: error == nil)
            }
        }
        guard updated else { return }
        try? await UMPConsentForm.loadAndPresentIfRequired(from: presenter())
    }

    /// いちばん上に出ている画面（シートが出ていればシート）。
    private static func presenter() -> UIViewController? {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows }
            .joined()
        var controller = windows.first { $0.isKeyWindow }?.rootViewController
        while let next = controller?.presentedViewController { controller = next }
        return controller
    }
}
