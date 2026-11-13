import XCTest

/// リワード広告がひと回り動くかの確認：デーモンを呼ぶ → クエスト達成 →「広告を見てボーナス」→ テスト広告を最後まで見て閉じる → ボーナスが入る。
/// 広告を本当に読み込むので、ネットにつながったシミュレータで、デバッグ版（Google のテスト広告）で流す。
final class RewardedBonusTour: XCTestCase {
    func testRewardedBonus() throws {
        let app = XCUIApplication()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        app.launch()

        // トラッキングの確認が出たら「しないように要求」を選ぶ。
        let deny = springboard.buttons["アプリにトラッキングしないように要求"]
        if deny.waitForExistence(timeout: 8) { deny.tap() }
        snap(app, "01_起動")

        app.buttons["眠気を感じたらタップ"].tap()
        // リワード広告の読み込みを待つ。
        Thread.sleep(forTimeInterval: 12)
        let firstQuest = app.buttons.matching(NSPredicate(format: "label CONTAINS 'EXP'")).firstMatch
        XCTAssertTrue(firstQuest.waitForExistence(timeout: 5))
        firstQuest.tap()

        let bonusButton = app.alerts.buttons.matching(NSPredicate(format: "label BEGINSWITH '広告を見てボーナス'")).firstMatch
        XCTAssertTrue(bonusButton.waitForExistence(timeout: 5), "リワード広告が読み込めていない（ボタンが出ない）")
        snap(app, "02_ボーナスのボタン")
        let goldBefore = goldText(app)
        bonusButton.tap()

        // テスト広告を最後まで見る（数秒〜30秒）。閉じるボタンが出たら押す。
        Thread.sleep(forTimeInterval: 5)
        snap(app, "03_広告")
        let bonusAlert = app.alerts["ボーナス獲得！"]
        let deadline = Date().addingTimeInterval(60)
        while !bonusAlert.exists && Date() < deadline {
            Thread.sleep(forTimeInterval: 3)
            let close = app.buttons.matching(NSPredicate(format: "label IN {'Close', 'Close Ad', '閉じる', 'close', 'Skip'} OR identifier CONTAINS[c] 'close'")).firstMatch
            if close.exists && close.isHittable {
                close.tap()
            }
        }
        snap(app, "04_広告のあと")
        XCTAssertTrue(bonusAlert.waitForExistence(timeout: 5), "ボーナスのお知らせが出ない")
        bonusAlert.buttons["OK"].tap()
        Thread.sleep(forTimeInterval: 1)
        snap(app, "05_ボーナス後")
        print("GOLD before=\(goldBefore) after=\(goldText(app))")
    }

    private func goldText(_ app: XCUIApplication) -> String {
        app.staticTexts.matching(NSPredicate(format: "label ENDSWITH ' G' AND label CONTAINS '🪙'")).firstMatch.label
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
