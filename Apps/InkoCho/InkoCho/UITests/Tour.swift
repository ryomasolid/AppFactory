import XCTest

/// はじめての起動から：登録 → 体重 → きょうの記録 → 言葉 → おせわ → 設定。審査用の画面収録にも使う。
final class Tour: XCTestCase {
    func testFirstMorning() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-noAds"]
        app.launch()
        wait(2)

        app.buttons["うちの子を登録する"].tap()
        let name = app.textFields["bird-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Sora")
        wait(1)
        app.navigationBars.buttons["保存"].tap()
        wait(2)

        // 体重をその場で
        let grams = app.textFields["quick-grams"]
        XCTAssertTrue(grams.waitForExistence(timeout: 5))
        grams.tap()
        grams.typeText("35.2")
        app.buttons["save-grams"].tap()
        wait(1)
        XCTAssertTrue(app.staticTexts["35.2g"].waitForExistence(timeout: 5))

        // きょうの記録
        app.buttons["open-today"].tap()
        XCTAssertTrue(app.buttons["look-chatty"].waitForExistence(timeout: 5))
        app.buttons["look-chatty"].tap()
        for _ in 0..<4 { app.steppers["outside"].buttons.element(boundBy: 1).tap() }
        wait(1)
        app.navigationBars.buttons["保存"].tap()
        wait(2)
        XCTAssertTrue(app.staticTexts["放鳥40分"].waitForExistence(timeout: 5))

        // 体重のグラフ
        app.tabBars.buttons["体重"].tap()
        wait(2)

        // 言葉
        app.tabBars.buttons["ことば"].tap()
        wait(1)
        app.buttons["add-word"].tap()
        let word = app.textFields["word-text"]
        XCTAssertTrue(word.waitForExistence(timeout: 5))
        word.typeText("Ohayo")
        app.navigationBars.buttons["保存"].tap()
        wait(2)
        XCTAssertTrue(app.staticTexts["「Ohayo」"].waitForExistence(timeout: 5))

        // おせわ
        app.tabBars.buttons["おせわ"].tap()
        wait(1)
        app.buttons["chore-cage"].tap()
        wait(2)

        app.tabBars.buttons["設定"].tap()
        wait(3)
        app.tabBars.buttons["きょう"].tap()
        wait(2)
    }

    private func wait(_ seconds: TimeInterval) { Thread.sleep(forTimeInterval: seconds) }
}
