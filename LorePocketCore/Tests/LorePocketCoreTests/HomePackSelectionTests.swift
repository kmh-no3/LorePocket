import XCTest
@testable import LorePocketCore

final class HomePackSelectionTests: XCTestCase {
    func testPrefersTheFirstPackThatCanStillBeDrawn() {
        let packs = [
            EngineFixtures.pack(id: "a", cards: [EngineFixtures.card(id: "a-1")], title: "A"),
            EngineFixtures.pack(id: "b", cards: [EngineFixtures.card(id: "b-1")], title: "B"),
        ]
        let featured = HomePackSelection.featured(in: packs) { $0 == "b" }
        XCTAssertEqual(featured?.id, "b")
    }

    func testFallsBackToTheFirstPackWhenNoneCanBeDrawn() {
        let packs = [
            EngineFixtures.pack(id: "a", cards: [EngineFixtures.card(id: "a-1")], title: "A"),
            EngineFixtures.pack(id: "b", cards: [EngineFixtures.card(id: "b-1")], title: "B"),
        ]
        let featured = HomePackSelection.featured(in: packs) { _ in false }
        XCTAssertEqual(featured?.id, "a")
    }

    func testEmptyLibraryHasNoFeaturedPack() {
        XCTAssertNil(HomePackSelection.featured(in: []) { _ in true })
    }
}
