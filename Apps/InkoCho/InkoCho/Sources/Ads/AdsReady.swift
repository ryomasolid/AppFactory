import AppTrackingTransparency
import GoogleMobileAds
import Observation
import StoreKit
import UIKit
import UserMessagingPlatform

/// 広告を出す前の手順を起動ごとに1回：Google の同意 → トラッキングの許可 → SDK の開始。
@MainActor
@Observable
final class AdsReady {
    enum Step { case notYet, running, done, skipped }

    private(set) var step: Step = AdsReady.quiet ? .skipped : .notYet
    private(set) var testFlight = false

    /// `-noAds`（テスト・録画）と `-demo`（スクショ）では広告を出さない。
    static var quiet: Bool {
        let a = ProcessInfo.processInfo.arguments
        return a.contains("-noAds") || a.contains("-demo")
    }

    func start() async {
        guard step == .notYet else { return }
        step = .running

        let info = UMPConsentInformation.sharedInstance
        let refreshed: Bool = await withCheckedContinuation { done in
            info.requestConsentInfoUpdate(with: UMPRequestParameters()) { error in done.resume(returning: error == nil) }
        }
        if refreshed {
            try? await UMPConsentForm.loadAndPresentIfRequired(from: Self.presenter())
        }
        guard info.canRequestAds else {
            step = .skipped
            return
        }
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            // 起動した直後は画面がまだ前に出ておらず、ダイアログが出ないことがある。
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
        if let verified = try? await AppTransaction.shared, case .verified(let t) = verified {
            testFlight = t.environment == .sandbox
        }
        _ = await GADMobileAds.sharedInstance().start()
        step = .done
    }

    /// Debug と TestFlight は Google のテスト用ユニット。
    var unit: String {
        #if DEBUG
        return Self.googleSample
        #else
        return testFlight || Self.mine.isEmpty ? Self.googleSample : Self.mine
        #endif
    }

    static let googleSample = "ca-app-pub-3940256099942544/2435281174"
    /// TODO: AdMob に「インコ帳」を登録したらバナーのユニット ID を入れる。
    static let mine = ""

    private static func presenter() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
        var vc = window?.rootViewController
        while let shown = vc?.presentedViewController { vc = shown }
        return vc
    }
}
