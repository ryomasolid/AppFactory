import XCTest

/// App Review に添える画面収録用の操作。新規インストール直後（記録ゼロ）から、
/// 個体の登録 → 記録 → まとめて給餌 → たまご → きろく → お知らせと CSV までをゆっくり見せる。
/// `simctl io recordVideo` で録画しながら、Release 構成で走らせる。
final class ReviewWalkthrough: XCTestCase {
    private let app = XCUIApplication()
    private let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    func testWalkthrough() throws {
        continueAfterFailure = true
        pause(3)
        app.launch()
        pause(3)

        // ケージ（空）→ 1匹目を登録
        tap(app.buttons["1匹目を登録する"]); pause(2)
        fillGeckoForm(name: "もち", morph: "マックスノー", knowsHatch: false)
        pause(3)

        // 2匹目
        tap(app.buttons["個体を追加"]); pause(2)
        fillGeckoForm(name: "きなこ", morph: "ハイイエロー", knowsHatch: true)
        pause(3)

        // もちの詳細 → ごはん・体重・脱皮を記録
        tap(app.buttons.containing("もち")); pause(3)
        tap(app.buttons["ごはん"]); pause(2)
        tap(app.buttons["保存"]); pause(3)
        tap(app.buttons["体重"]); pause(2)
        let grams = app.textFields["例: 45.5"]
        tap(grams); pause(1)
        grams.typeText("62.5"); pause(2)
        tap(app.buttons["保存"]); pause(3)
        tap(app.buttons["脱皮"]); pause(2)
        tap(app.buttons["保存"]); pause(3)
        app.swipeUp(velocity: .slow); pause(3)
        app.swipeDown(velocity: .fast); pause(2)
        tap(app.navigationBars.buttons.element(boundBy: 0)); pause(3)

        // ごはんをまとめて記録（きなこは拒食に）
        tap(app.buttons.containing("ごはんをまとめて記録")); pause(3)
        // 行のボタンは中央を押しても効かないので、名前の文字を押す。きなこ（ごはんの日）は最初から選ばれている。
        let rows = app.collectionViews.firstMatch
        tap(rows.staticTexts["もち"]); pause(2)
        tap(rows.buttons.matching(identifier: "食べた").element(boundBy: 1)); pause(2)
        tap(app.buttons.containing("記録する（")); pause(4)

        // たまご
        openTab("たまご"); pause(2)
        tap(app.buttons["産卵を記録する"]); pause(3)
        tap(app.buttons["保存"]); pause(4)

        // きろく
        openTab("きろく"); pause(3)
        app.swipeUp(velocity: .slow); pause(3)

        // せってい → お知らせ → CSV
        openTab("せってい"); pause(2)
        flip(app.switches["ごはんの日に知らせる"]); pause(2)
        let allow = springboard.alerts.buttons["許可"]
        if allow.waitForExistence(timeout: 8) { pause(2); allow.tap() }
        pause(3)
        tap(app.buttons["記録をCSVで書き出す"]); pause(5)
        let close = app.buttons["閉じる"]
        if close.waitForExistence(timeout: 5) { close.tap() } else { app.swipeDown(velocity: .fast) }
        pause(3)

        // ケージに戻って全体を見せる
        openTab("ケージ"); pause(5)
    }

    /// 名前とモルフを入れ、ハッチ日は入れる／入れない（入れないとアダルト扱い）。
    private func fillGeckoForm(name: String, morph: String, knowsHatch: Bool) {
        let nameField = app.textFields["名前（例: もち）"]
        tap(nameField); pause(1)
        nameField.typeText(name); pause(1)
        let morphField = app.textFields["モルフ（例: ハイイエロー）"]
        tap(morphField); pause(1)
        morphField.typeText(morph); pause(1)
        app.navigationBars.firstMatch.tap(); pause(1)
        if knowsHatch {
            flip(app.switches["ハッチ日がわかる"]); pause(3)
        }
        tap(app.buttons["保存"])
    }

    /// Form のトグルは行の中央を押しても切り替わらないので、右端のスイッチ本体を押す。
    private func flip(_ toggle: XCUIElement) {
        guard toggle.waitForExistence(timeout: 10) else {
            XCTFail("見つからない: \(toggle)")
            return
        }
        let knob = toggle.switches.firstMatch
        if knob.exists {
            knob.tap()
        } else {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        }
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
