import XCTest

/// App Review に添える画面収録用の操作。新規インストール直後から、
/// 同意 → ATT → ホーム → 行列の通知 → 駅 → 記事 → ガツログ → 通知の到着までをゆっくり見せる。
/// `simctl io recordVideo` で録画しながら、Release 構成で走らせる。
final class ReviewWalkthrough: XCTestCase {
    private let app = XCUIApplication()
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    func testWalkthrough() throws {
        continueAfterFailure = true
        pause(3)
        app.launch()
        pause(2)
        answerConsentAndTracking()
        pause(3)

        // ホーム
        app.swipeUp(velocity: .slow); pause(2)
        app.swipeUp(velocity: .slow); pause(2)
        app.swipeDown(velocity: .fast); app.swipeDown(velocity: .fast); pause(2)

        // ツール › 行列の待ち時間 › 通知を予約
        openTab("ツール"); pause(2)
        tap(app.staticTexts["行列の待ち時間"]); pause(3)
        tap(app.staticTexts["入店の5分前に通知する"]); pause(2)
        let allow = springboard.alerts.buttons["許可"]
        if allow.waitForExistence(timeout: 8) { allow.tap() }
        let scheduledAt = Date.now
        pause(4)

        // 駅
        openTab("駅"); pause(2)
        tap(app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "新宿")).firstMatch); pause(3)
        app.swipeUp(velocity: .slow); pause(2)
        app.swipeUp(velocity: .slow); pause(2)
        app.swipeUp(velocity: .slow); pause(2)

        // 読む › 実食レポート
        openTab("読む"); pause(2)
        tap(app.buttons.containing("花木流味噌 日吉店の味噌ラーメン")); pause(3)
        app.swipeUp(velocity: .slow); pause(2)
        app.swipeUp(velocity: .slow); pause(2)
        app.swipeUp(velocity: .slow); pause(2)

        // ガツログ › 食事を1件記録
        openTab("ガツログ"); pause(2)
        tap(app.staticTexts["食べたものを記録"]); pause(2)
        tap(app.staticTexts["牛丼（並盛）"]); pause(3)
        tap(app.buttons["完了"]); pause(3)

        // 行列の通知が届くまで待つ（予約から約3分）。
        let deadline = scheduledAt.addingTimeInterval(4 * 60)
        let banner = springboard.descendants(matching: .any).containing("そろそろ順番です")
        while Date.now < deadline, !banner.exists { pause(2) }
        XCTAssertTrue(banner.exists, "行列の通知が届かなかった")
        pause(8)
    }

    /// UMP の説明画面（出たとき）と ATT の許可画面に答える。
    private func answerConsentAndTracking() {
        let deadline = Date.now.addingTimeInterval(45)
        while Date.now < deadline {
            let tracking = springboard.alerts.matching(NSPredicate(format: "label CONTAINS %@", "トラッキング")).firstMatch
            if tracking.exists {
                pause(3)
                tracking.buttons["許可"].tap()
                return
            }
            let next = app.webViews.buttons["続行"].firstMatch
            if next.exists {
                pause(3)
                next.tap()
                pause(1)
            }
            pause(0.5)
        }
        XCTFail("ATT の許可画面が出なかった")
    }

    private func tap(_ element: XCUIElement) {
        guard element.waitForExistence(timeout: 10) else {
            XCTFail("見つからない: \(element)")
            return
        }
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    /// タブを開く。通知の許可画面を閉じた直後は最初のタップが効かないことがあるので、選ばれるまで押し直す。
    private func openTab(_ title: String) {
        let button = app.tabBars.buttons[title]
        for _ in 0..<4 {
            button.tap()
            pause(1)
            if button.isSelected { return }
        }
        XCTFail("タブが開かない: \(title)")
    }

    private func pause(_ seconds: Double) {
        Thread.sleep(forTimeInterval: seconds)
    }
}

private extension XCUIElementQuery {
    func containing(_ text: String) -> XCUIElement {
        matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }
}
