import XCTest

/// はじめての起動から：目安を選ぶ → きょうをしめる → 取り消してお金をつける → カレンダー → 設定。審査用の録画にも使う。
final class Tour: XCTestCase {
    func testFirstDay() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-noAds"]
        app.launch()
        wait(2)

        let start = app.buttons["start"]
        if start.waitForExistence(timeout: 5) {
            app.buttons["usual-800"].tap()
            app.buttons["budget-10000"].tap()
            wait(1)
            start.tap()
        }
        wait(2)

        // きょうをムダゼロでしめる
        let close = app.buttons["close-day"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        wait(1)
        XCTAssertTrue(app.staticTexts["0円の日！"].waitForExistence(timeout: 5))
        wait(1)

        // 必要な出費を足すと「ムダゼロ」になる
        app.buttons["add-spend"].tap()
        let amount = app.textFields["amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        app.segmentedControls["want-picker"].buttons["必要な出費"].tap()
        amount.tap()
        amount.typeText("1280")
        app.buttons["type-groceries"].tap()
        wait(1)
        app.navigationBars.buttons["保存"].tap()
        wait(1)
        XCTAssertTrue(app.staticTexts["ムダゼロ！"].waitForExistence(timeout: 5))

        // ついつい を足すと「ついつい」
        app.buttons["add-spend"].tap()
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        amount.tap()
        amount.typeText("380")
        app.buttons["type-cafe"].tap()
        wait(1)
        app.navigationBars.buttons["保存"].tap()
        wait(2)

        app.tabBars.buttons["カレンダー"].tap()
        wait(3)

        app.tabBars.buttons["設定"].tap()
        wait(2)
        app.tabBars.buttons["きょう"].tap()
        wait(2)
    }

    private func wait(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
