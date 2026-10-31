import XCTest
@testable import LorePocketCore

final class VariantSelectionTests: XCTestCase {
    func testOwnedVariantBecomesTheSelection() {
        let next = VariantSelection.choose(current: "common", requested: "foil", ownedIds: ["common", "foil"])
        XCTAssertEqual(next, "foil")
    }

    func testUnownedVariantDoesNotChangeTheSelection() {
        let next = VariantSelection.choose(current: "common", requested: "legend", ownedIds: ["common"])
        XCTAssertEqual(next, "common")
        XCTAssertNil(VariantSelection.choose(current: nil, requested: "legend", ownedIds: []))
    }
}
