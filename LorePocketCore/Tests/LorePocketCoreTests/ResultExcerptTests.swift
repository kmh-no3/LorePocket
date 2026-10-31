import XCTest
@testable import LorePocketCore

final class ResultExcerptTests: XCTestCase {
    func testShortTextStaysWhole() {
        let result = ResultExcerpt.clip("  短い文です。  ", limit: 20)
        XCTAssertEqual(result.text, "短い文です。")
        XCTAssertFalse(result.truncated)
    }

    func testLongTextIsCutAndMarked() {
        let source = String(repeating: "あ", count: 40)
        let result = ResultExcerpt.clip(source, limit: 12)
        XCTAssertTrue(result.truncated)
        XCTAssertTrue(result.text.hasSuffix("…"))
        XCTAssertEqual(result.text.count, 13)
    }
}
