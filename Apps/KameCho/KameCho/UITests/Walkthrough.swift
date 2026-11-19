import XCTest

/// 最初の起動から：カメを登録 → ごはん → 水換え → 計る → 温度 → 体のようす → 器具 → 冬眠 → 設定。審査用の録画にも使う。
final class Walkthrough: XCTestCase {
    func testFirstWeek() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-noAds"]
        app.launch()
        pause(2)

        app.buttons["うちのカメを登録する"].tap()
        let name = app.textFields["turtle-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText("Kame")
        pause(1)
        app.navigationBars.buttons["保存"].tap()
        pause(2)

        // ごはん
        let feed = app.buttons["done-feed"]
        XCTAssertTrue(feed.waitForExistence(timeout: 5))
        feed.tap()
        XCTAssertTrue(app.navigationBars.buttons["保存"].waitForExistence(timeout: 5))
        pause(1)
        app.navigationBars.buttons["保存"].tap()
        pause(1)

        // 水換え
        app.buttons["done-water"].tap()
        pause(1)
        XCTAssertTrue(app.staticTexts["水換え"].firstMatch.exists)

        // 計る
        app.buttons["done-measure"].tap()
        let shell = app.textFields["measure-shell"]
        XCTAssertTrue(shell.waitForExistence(timeout: 5))
        shell.tap()
        shell.typeText("85")
        let grams = app.textFields["measure-grams"]
        grams.tap()
        grams.typeText("142")
        app.navigationBars.buttons["保存"].tap()
        pause(1)

        // 温度
        let base = app.textFields["temp-base"]
        base.tap()
        base.typeText("26")
        app.textFields["temp-spot"].tap()
        app.textFields["temp-spot"].typeText("32")
        app.buttons["save-temp"].tap()
        pause(1)

        // 体のようす
        app.swipeUp()
        app.buttons["open-check"].tap()
        XCTAssertTrue(app.buttons["sign-notBasking"].waitForExistence(timeout: 5))
        app.buttons["sign-notBasking"].tap()
        pause(1)
        app.navigationBars.buttons["保存"].tap()
        pause(2)

        // 成長
        app.tabBars.buttons["成長"].tap()
        pause(2)

        // 器具
        app.tabBars.buttons["器具"].tap()
        pause(1)
        app.buttons["add-gear"].tap()
        let gearName = app.textFields["gear-name"]
        XCTAssertTrue(gearName.waitForExistence(timeout: 5))
        gearName.tap()
        gearName.typeText("UVB 10.0")
        app.navigationBars.buttons["保存"].tap()
        pause(2)
        XCTAssertTrue(app.staticTexts["UVB 10.0"].waitForExistence(timeout: 5))

        // 冬眠
        app.tabBars.buttons["成長"].tap()
        pause(1)
        app.swipeUp()
        let start = app.buttons["start-rest"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()
        XCTAssertTrue(app.navigationBars.buttons["始める"].waitForExistence(timeout: 5))
        pause(1)
        app.navigationBars.buttons["始める"].tap()
        pause(2)
        XCTAssertTrue(app.buttons["end-rest"].waitForExistence(timeout: 5))

        app.tabBars.buttons["きょう"].tap()
        pause(2)

        app.tabBars.buttons["設定"].tap()
        pause(2)
        app.tabBars.buttons["きょう"].tap()
        pause(1)
    }

    private func pause(_ seconds: TimeInterval) { Thread.sleep(forTimeInterval: seconds) }
}
