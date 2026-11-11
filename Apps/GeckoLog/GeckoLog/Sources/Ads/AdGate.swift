import AppTrackingTransparency
import GoogleMobileAds
import Observation
import StoreKit
import UIKit
import UserMessagingPlatform

/// 広告を出してよいかの門。起動後に 同意（UMP）→ トラッキング許可（ATT）→ SDK の起動 を一度だけ進める。
///
/// げこログは起動してすぐ「ごはんをまとめて記録」を押す使われ方なので、最初の画面を描いてから進め、
/// どこかで止まっても記録の操作は妨げない。門が開くまで棚（`BannerShelf`）は高さ0で何も置かない。
@MainActor
@Observable
final class AdGate {
    enum Door: Equatable {
        /// まだ何もしていない。
        case shut
        /// 同意や許可を取っている最中。
        case opening
        /// 広告を頼んでよい。
        case open
        /// この起動では広告を出さない（撮影・審査用の録画・同意が得られない）。
        case sealed
    }

    /// 起動引数 `-noAds`（審査用の録画・テスト）か、見本データ（`-showcase`）のときは門を閉じたままにする。
    static var isSealedByLaunch: Bool {
        ProcessInfo.processInfo.arguments.contains("-noAds") || Showcase.isOn
    }

    private(set) var door: Door = AdGate.isSealedByLaunch ? .sealed : .shut

    /// TestFlight（sandbox）で動いているか。本番の広告は配信制限で届かないことがあり、
    /// 自分の端末で本番の広告を踏むのも避けたいので、sandbox では Google のテスト用ユニットを使う。
    private(set) var sandboxed = false

    /// 1回だけ進める。2回目以降は何もしない。
    func open() async {
        guard door == .shut else { return }
        door = .opening

        let consent = UMPConsentInformation.sharedInstance
        if await refreshConsent(consent) {
            try? await UMPConsentForm.loadAndPresentIfRequired(from: Self.topController())
        }
        guard consent.canRequestAds else {
            door = .sealed
            return
        }

        // ATT のダイアログは画面が前面にあるときしか出ない。起動直後の描画と重ならないよう少し待つ。
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            try? await Task.sleep(for: .milliseconds(700))
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }

        if case .verified(let transaction)? = try? await AppTransaction.shared {
            sandboxed = transaction.environment == .sandbox
        }
        _ = await GADMobileAds.sharedInstance().start()
        door = .open
    }

    /// 同意情報を取り直す。取れなくても前回の同意が残っていれば広告は頼めるので、成否だけ返す。
    private func refreshConsent(_ consent: UMPConsentInformation) async -> Bool {
        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false
        return await withCheckedContinuation { continuation in
            consent.requestConsentInfoUpdate(with: parameters) { error in
                continuation.resume(returning: error == nil)
            }
        }
    }

    /// いちばん手前の画面（同意フォームを載せる先）。
    private static func topController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var controller = scene?.keyWindow?.rootViewController
        while let next = controller?.presentedViewController { controller = next }
        return controller
    }
}
