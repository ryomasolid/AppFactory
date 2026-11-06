import XCTest

/// ホームの検索欄の見え方（ライト・ダーク両方で撮る）。
final class HomeFieldCheck: XCTestCase {
    func testHomeField() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(4)
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = "home"; a.lifetime = .keepAlways; add(a)
    }
}
