import XCTest

/// App Store 用の素のスクショ（広告なし・記録はデモ）。iPhone 17 Pro Max（1320x2868）で撮る。
final class StoreShots: XCTestCase {
    private let shots: [(String, [String])] = [
        ("home", []),
        ("search", ["-homeQuery", "名古屋"]),
        ("japan", ["-tab", "stations", "-push", "japan:博多"]),
        ("quantity", ["-tab", "tools", "-push", "tool:quantity"]),
        ("report", ["-tab", "read", "-push", "report:shibuya-dogenzaka-mammoth"]),
        ("log", ["-tab", "log"]),
    ]

    func testShots() throws {
        for (name, args) in shots {
            let app = XCUIApplication()
            app.launchArguments = ["-hideAds", "YES", "-demoLog", "YES"] + args
            app.launch()
            sleep(3)
            let a = XCTAttachment(screenshot: app.screenshot())
            a.name = "shot-\(name)"
            a.lifetime = .keepAlways
            add(a)
            app.terminate()
        }
    }
}
