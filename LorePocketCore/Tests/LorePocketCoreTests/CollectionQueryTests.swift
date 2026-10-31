import XCTest
@testable import LorePocketCore

final class CollectionQueryTests: XCTestCase {
    func testOwnershipFilter() {
        XCTAssertTrue(CollectionQuery.includes(isOwned: false, ownership: .all))
        XCTAssertTrue(CollectionQuery.includes(isOwned: true, ownership: .owned))
        XCTAssertFalse(CollectionQuery.includes(isOwned: false, ownership: .owned))
        XCTAssertTrue(CollectionQuery.includes(isOwned: false, ownership: .unowned))
    }

    func testOwnedSearchIncludesBackgroundAndTopics() {
        let card = Card(
            id: "sample-pack-001-001",
            genre: ["哲学"],
            text: "短い引用",
            person: "架空の人",
            background: "港の背景について",
            topics: ["潮風"]
        )
        XCTAssertTrue(CollectionQuery.matches(card: card, isOwned: true, query: "港"))
        XCTAssertTrue(CollectionQuery.matches(card: card, isOwned: true, query: "潮風"))
        XCTAssertTrue(CollectionQuery.matches(card: card, isOwned: true, query: ""))
    }

    func testUnownedSearchDoesNotReadTheBody() {
        let card = Card(
            id: "sample-pack-001-001",
            genre: ["哲学"],
            text: "秘密の引用",
            person: "架空の人",
            background: "秘密の背景",
            topics: ["秘密"]
        )
        XCTAssertFalse(CollectionQuery.matches(card: card, isOwned: false, query: "秘密"))
        XCTAssertTrue(CollectionQuery.matches(card: card, isOwned: false, query: "哲学"))
    }

    func testColumnCountFollowsWidth() {
        XCTAssertEqual(CollectionQuery.columnCount(containerWidth: 320), 2)
        XCTAssertEqual(CollectionQuery.columnCount(containerWidth: 389), 2)
        XCTAssertEqual(CollectionQuery.columnCount(containerWidth: 390), 3)
    }
}
