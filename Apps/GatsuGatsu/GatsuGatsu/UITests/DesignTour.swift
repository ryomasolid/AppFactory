import XCTest

/// 主な画面を順に撮る（見た目の確認用）。
final class DesignTour: XCTestCase {
    func testTour() throws {
        let app = XCUIApplication()
        app.launch()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for _ in 0..<10 {
            let next = app.webViews.buttons["続行"].firstMatch
            if next.exists, next.isHittable { next.tap() }
            let alert = springboard.alerts.firstMatch
            if alert.exists { alert.buttons.element(boundBy: alert.buttons.count - 1).tap(); break }
            sleep(1)
        }
        sleep(2)
        shot(app, "a-home")
        app.swipeUp(); sleep(1); shot(app, "b-home-2")
        app.swipeDown(); app.swipeDown(); sleep(1)
        let field = app.textFields.firstMatch
        field.tap(); field.typeText("梅田"); sleep(2); shot(app, "c-home-search")
        app.buttons["入力を消す"].tap(); sleep(1)
        app.staticTexts["新宿"].firstMatch.tap(); sleep(2); shot(app, "d-station")
        for (tab, name) in [("駅で探す", "e-stations"), ("記事", "f-read"), ("ツール", "g-tools"), ("記録", "h-log")] {
            app.tabBars.buttons[tab].tap(); sleep(2); shot(app, name)
        }
        app.tabBars.buttons["ツール"].tap(); sleep(1)
        app.staticTexts["外食の量 早見表"].tap(); sleep(2); shot(app, "i-quantity")
    }

    private func shot(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
}
