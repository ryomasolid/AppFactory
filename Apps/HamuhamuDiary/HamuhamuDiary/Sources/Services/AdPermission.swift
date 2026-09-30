import AppTrackingTransparency
import GoogleMobileAds
import Observation
import UIKit
import UserMessagingPlatform

/// 広告を出してよいかどうかの状態。バナーはこれが `.ready` になってから枠を作る。
///
/// はむ日記は起動してすぐ記録ボタンを押す使われ方が多いので、最初の画面を描いたあとで
/// 次の順に進める（どこかで止まっても、アプリの操作は妨げない）。
///   同意情報の確認（UMP、必要な地域だけフォーム）→ トラッキング許可（ATT）→ AdMob の起動
@MainActor
@Observable
final class AdPermission {
    enum Phase: Equatable {
        case idle
        case asking
        /// 広告を出せる。
        case ready
        /// 同意が得られない・撮影用などで広告を出さない。
        case off
    }

    private(set) var phase: Phase = Launch.hideAds ? .off : .idle

    /// 1回だけ進める。2回目以降の呼び出しは何もしない。
    func begin() async {
        guard phase == .idle else { return }
        phase = .asking

        let consent = UMPConsentInformation.sharedInstance
        if await updateConsentInfo(consent) {
            try? await UMPConsentForm.loadAndPresentIfRequired(from: Self.frontController())
        }
        guard consent.canRequestAds else {
            phase = .off
            return
        }

        // ATT は画面が前面にあるときしか出ない。起動直後の遷移と重ならないよう少し待つ。
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            try? await Task.sleep(for: .milliseconds(600))
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
        _ = await GADMobileAds.sharedInstance().start()
        phase = .ready
    }

    /// 同意情報を最新にする。失敗しても前回の同意が残っていれば広告は出せるので、結果だけ返す。
    private func updateConsentInfo(_ consent: UMPConsentInformation) async -> Bool {
        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false
        return await withCheckedContinuation { continuation in
            consent.requestConsentInfoUpdate(with: parameters) { error in
                continuation.resume(returning: error == nil)
            }
        }
    }

    private static func frontController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        else { return nil }
        var front = scene.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = front?.presentedViewController { front = presented }
        return front
    }
}
