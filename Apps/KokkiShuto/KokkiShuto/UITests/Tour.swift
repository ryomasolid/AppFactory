import XCTest

/// はじめての起動から：国旗→国名を10問 → 結果 → 国名→首都を少し → ずかん（地域・検索）。審査用の録画にも使う。
final class Tour: XCTestCase {
    func testTour() throws {
        let app = XCUIApplication()
        app.launch()
        wait(2)

        // 国旗 → 国名（10問）
        app.buttons["mode.flagToName"].tap()
        wait(1.5)
        for _ in 0..<10 { answer(app) }

        let close = app.buttons["おわる"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        wait(2)
        app.swipeUp()
        wait(1.5)
        close.tap()
        wait(2)

        // 国名 → 首都（3問だけ解いてやめる）
        app.buttons["mode.nameToCapital"].tap()
        wait(1.5)
        for _ in 0..<3 { answer(app) }
        app.buttons["やめる"].tap()
        wait(1.5)

        // 国名 → 国旗（2問）
        app.buttons["mode.nameToFlag"].tap()
        wait(1.5)
        for _ in 0..<2 { answer(app) }
        app.buttons["やめる"].tap()
        wait(1.5)

        // ずかん
        app.tabBars.buttons["ずかん"].tap()
        wait(2)
        app.buttons["ヨーロッパ"].tap()
        wait(1.5)
        app.swipeUp()
        wait(1.5)
        app.swipeDown()
        app.swipeDown()
        wait(1)
        app.buttons["すべて"].firstMatch.tap()
        let search = app.searchFields.firstMatch
        if search.waitForExistence(timeout: 3) {
            search.tap()
            search.typeText("ボリビア")
            wait(2.5)
        }
        app.tabBars.buttons["クイズ"].tap()
        wait(2)
    }

    /// 2番目の選択肢を選ぶ（正解なら自動で次へ、まちがいなら「つぎへ」）。
    private func answer(_ app: XCUIApplication) {
        let choice = app.buttons["choice-2"]
        XCTAssertTrue(choice.waitForExistence(timeout: 5))
        wait(1)
        choice.tap()
        let next = app.buttons["next"]
        wait(1.6)
        if next.exists && next.isHittable && app.staticTexts["ざんねん"].exists {
            next.tap()
            wait(0.8)
        }
    }

    private func wait(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }
}
