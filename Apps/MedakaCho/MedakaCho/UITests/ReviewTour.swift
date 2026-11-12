import XCTest

/// 審査用の画面収録：はじめての起動から、容器の登録 → 記録 → 卵 → 品種 → 設定 をひと回りする。
final class ReviewTour: XCTestCase {
    func testTour() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-quiet"]
        app.launch()
        pause(2)

        app.buttons["容器を登録する"].tap()
        let name = app.textFields["vessel-name"]
        name.tap()
        name.typeText("Porch bowl")
        pause(1)
        app.buttons["楊貴妃"].tap()
        pause(1)
        app.navigationBars.buttons["保存"].tap()
        pause(2)

        app.staticTexts["Porch bowl"].tap()
        pause(2)
        app.buttons["quick-feed"].tap()
        pause(2)
        app.buttons["quick-waterChange"].tap()
        pause(1)
        app.navigationBars.buttons["保存"].tap()
        pause(2)
        app.buttons["quick-eggs"].tap()
        pause(1)
        app.navigationBars.buttons["保存"].tap()
        pause(2)
        app.swipeUp()
        pause(2)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        pause(2)

        for tab in ["卵", "品種", "設定"] {
            app.tabBars.buttons[tab].tap()
            pause(3)
        }
        app.tabBars.buttons["容器"].tap()
        pause(2)
    }

    private func pause(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
