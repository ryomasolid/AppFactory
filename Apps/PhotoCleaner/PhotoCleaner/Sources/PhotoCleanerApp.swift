import GoogleMobileAds
import SwiftUI

@main
struct PhotoCleanerApp: App {
    init() {
        // AdMob SDK を起動時に初期化する。
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
