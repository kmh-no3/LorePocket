import XCTest

/// 図鑑の所持カードをタップしたときに詳細へ遷移するかを切り分けるプローブ。
final class CollectionNavProbeUITests: XCTestCase {
    func testOpenOwnedCardFromCollectionTab() {
        let app = XCUIApplication()
        app.launch()
        let dir = ProcessInfo.processInfo.environment["SHOT_DIR"] ?? NSTemporaryDirectory()
        app.tabBars.buttons["図鑑"].tap()
        let row = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Sample Pack'")).firstMatch
        (row.waitForExistence(timeout: 5) ? row : app.cells.firstMatch).tap()
        try? app.debugDescription.write(toFile: "\(dir)/probe-tree0.txt", atomically: true, encoding: .utf8)
        XCTAssertTrue(app.navigationBars["コレクション"].waitForExistence(timeout: 5))
        let owned = app.scrollViews.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Sample '")).firstMatch
        XCTAssertTrue(owned.waitForExistence(timeout: 5), "所持カードが見つからない")
        try? app.debugDescription.write(toFile: "\(dir)/probe-tree.txt", atomically: true, encoding: .utf8)
        owned.tap()
        let opened = app.navigationBars["詳細"].waitForExistence(timeout: 5)
        try? XCUIScreen.main.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "\(dir)/probe-after-tap.png"))
        XCTAssertTrue(opened, "図鑑タブ経由で所持カードの詳細へ遷移しない")
    }
}
