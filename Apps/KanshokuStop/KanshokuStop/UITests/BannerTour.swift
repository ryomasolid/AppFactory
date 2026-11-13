import XCTest

/// 広告がひと回り出るかの確認：はじめての起動 → トラッキングの確認 →「きょう」と「カレンダー」それぞれの画面下にバナーが出る。
/// 広告を本当に読み込むので、ネットにつながったシミュレータで、デバッグ版（Google のテスト広告）で流す。
final class BannerTour: XCTestCase {
    func testBannersOnBothTabs() throws {
        let app = XCUIApplication()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        app.launch()

        let deny = springboard.buttons["アプリにトラッキングしないように要求"]
        XCTAssertTrue(deny.waitForExistence(timeout: 10), "トラッキングの確認が出ない")
        deny.tap()

        // テスト広告には「Test mode」の札が付く。
        let testBadge = app.staticTexts["Test mode"]
        XCTAssertTrue(testBadge.waitForExistence(timeout: 20), "きょうの画面にバナーが出ない")
        Thread.sleep(forTimeInterval: 2)
        snap(app, "01_きょう")

        // 記録してもバナーは残る。
        app.buttons["間食しなかった"].tap()
        Thread.sleep(forTimeInterval: 1)

        app.tabBars.buttons["カレンダー"].tap()
        let calendarBadge = app.staticTexts["Test mode"]
        XCTAssertTrue(calendarBadge.waitForExistence(timeout: 20), "カレンダーの画面にバナーが出ない")
        Thread.sleep(forTimeInterval: 2)
        snap(app, "02_カレンダー")
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
