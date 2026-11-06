import XCTest

/// 全国の駅名検索を Release 構成で触り、画面を残す（目で確かめる用）。
final class NationwideSearchCheck: XCTestCase {
    func testSearchAndOpenStation() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-skipATT", "YES"]
        app.launch()
        dismissPrompts(app)

        app.tabBars.buttons["駅で探す"].tap()
        snapshot(app, "1-index")
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("府中")
        sleep(2)
        snapshot(app, "2-fuchu")

        let first = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "府中駅")).firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap()
        sleep(2)
        snapshot(app, "3-fuchu-station")
        app.navigationBars.buttons["いつもの駅にする"].tap()
        sleep(1)
        XCTAssertTrue(app.navigationBars.buttons["いつもの駅から外す"].exists)

        app.navigationBars.buttons.firstMatch.tap()
        sleep(2)
        snapshot(app, "4-back")
        field.buttons.firstMatch.tap()  // 入力を消す
        field.tap()
        field.typeText("三鷹")
        sleep(2)
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "三鷹駅")).firstMatch.tap()
        sleep(2)
        snapshot(app, "5-mitaka")

        app.tabBars.buttons["ホーム"].tap()
        sleep(2)
        let chip = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "府中")).firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        snapshot(app, "6-home-saved")
        chip.tap()
        sleep(2)
        XCTAssertTrue(app.staticTexts["京王線"].exists)
        app.navigationBars.buttons["いつもの駅から外す"].tap()
    }

    private func dismissPrompts(_ app: XCUIApplication) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for _ in 0..<12 {
            let next = app.webViews.buttons["続行"].firstMatch
            if next.exists, next.isHittable { next.tap() }
            let alert = springboard.alerts.firstMatch
            if alert.exists { alert.buttons.element(boundBy: alert.buttons.count - 1).tap(); return }
            sleep(1)
        }
    }

    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
