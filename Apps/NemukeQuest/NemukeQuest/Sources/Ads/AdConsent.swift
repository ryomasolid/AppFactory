import AppTrackingTransparency
import GoogleMobileAds
import Observation
import StoreKit
import UIKit
import UserMessagingPlatform

/// 広告を出す前の手続き（UMP の同意 → ATT → SDK の開始）を、起動ごとに1回だけ進める。
@MainActor
@Observable
final class AdConsent {
    enum Phase {
        case idle, working, ready, off
    }

    /// `-quiet`（テスト・審査の録画）と `-sample`（スクショ）のときは広告を出さない。
    static var silencedByLaunch: Bool {
        let args = ProcessInfo.processInfo.arguments
        return args.contains("-quiet") || args.contains("-sample")
    }

    private(set) var phase: Phase = AdConsent.silencedByLaunch ? .off : .idle
    /// TestFlight など sandbox で動いているか。そのときはテスト広告を使う。
    private(set) var isSandbox = false

    func begin() async {
        guard phase == .idle else { return }
        phase = .working

        let info = UMPConsentInformation.sharedInstance
        let parameters = UMPRequestParameters()
        parameters.tagForUnderAgeOfConsent = false
        let updated: Bool = await withCheckedContinuation { done in
            info.requestConsentInfoUpdate(with: parameters) { error in done.resume(returning: error == nil) }
        }
        if updated {
            try? await UMPConsentForm.loadAndPresentIfRequired(from: Self.frontController())
        }
        guard info.canRequestAds else {
            phase = .off
            return
        }

        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            // 起動直後はまだ画面が前に出ておらず、ダイアログが出ないことがある。
            try? await Task.sleep(for: .seconds(0.8))
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }

        if let result = try? await AppTransaction.shared, case .verified(let transaction) = result {
            isSandbox = transaction.environment == .sandbox
        }
        _ = await GADMobileAds.sharedInstance().start()
        phase = .ready
    }

    private static func frontController() -> UIViewController? {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        var top = window?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}
