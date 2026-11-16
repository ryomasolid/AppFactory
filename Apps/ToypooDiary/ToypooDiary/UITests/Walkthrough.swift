import XCTest

/// はじめての起動から、登録 → 日記 → トリミング → 体重・予防 → 設定 をひと回りする（審査用の画面収録にも使う）。
final class Walkthrough: XCTestCase {
    func testFirstDay() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-calm"]
        app.launch()
        rest(2)

        app.buttons["うちの子を登録する"].tap()
        let name = app.textFields["dog-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Mugi")
        rest(1)
        app.navigationBars.buttons["保存"].tap()
        rest(2)

        // 日記
        app.buttons["write-today"].tap()
        XCTAssertTrue(app.buttons["mood-happy"].waitForExistence(timeout: 5))
        app.buttons["mood-happy"].tap()
        rest(1)
        app.steppers["walk-count"].buttons.element(boundBy: 1).tap()
        app.steppers["walk-count"].buttons.element(boundBy: 1).tap()
        for _ in 0..<6 { app.steppers["walk-minutes"].buttons.element(boundBy: 1).tap() }
        rest(1)
        app.navigationBars.buttons["保存"].tap()
        rest(2)
        XCTAssertTrue(app.staticTexts["散歩30分"].waitForExistence(timeout: 5))

        // トリミング
        app.tabBars.buttons["トリミング"].tap()
        rest(1)
        app.buttons["add-trim"].tap()
        XCTAssertTrue(app.buttons["テディベアカット"].waitForExistence(timeout: 5))
        app.buttons["テディベアカット"].tap()
        rest(1)
        app.navigationBars.buttons["保存"].tap()
        rest(2)
        XCTAssertTrue(app.staticTexts["カットしたて"].waitForExistence(timeout: 5))

        // 体重と予防
        app.tabBars.buttons["けんこう"].tap()
        rest(1)
        app.buttons["add-weight"].tap()
        let kg = app.textFields["weight-kg"]
        XCTAssertTrue(kg.waitForExistence(timeout: 5))
        kg.typeText("3.2")
        app.navigationBars.buttons["保存"].tap()
        rest(2)
        XCTAssertTrue(app.staticTexts["3.20kg"].waitForExistence(timeout: 5))
        app.staticTexts["フィラリアの薬"].tap()
        rest(1)
        app.buttons["done-heartworm"].tap()
        rest(2)
        app.navigationBars.buttons.element(boundBy: 0).tap()
        rest(2)

        app.tabBars.buttons["設定"].tap()
        rest(3)
        app.tabBars.buttons["日記"].tap()
        rest(2)
    }

    private func rest(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
