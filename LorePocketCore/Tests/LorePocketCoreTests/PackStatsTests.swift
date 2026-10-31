import XCTest
@testable import LorePocketCore

final class PackStatsTests: XCTestCase {
    func testCountsIgnoreCardsOutsideThePack() {
        let cards = [
            EngineFixtures.card(id: "sample-pack-001-001"),
            EngineFixtures.card(id: "sample-pack-001-002"),
        ]
        let pack = EngineFixtures.pack(cards: cards)
        let now = Date(timeIntervalSince1970: 10)
        let progress = PackProgress(
            owned: [
                OwnedCard(cardId: cards[0].id, variantId: "common", obtainedAt: now),
                OwnedCard(cardId: cards[0].id, variantId: "common", obtainedAt: now.addingTimeInterval(5)),
                OwnedCard(cardId: "missing", variantId: "legend", obtainedAt: now),
                OwnedCard(cardId: cards[0].id, variantId: "not-a-variant", obtainedAt: now),
            ],
            lastDrawDate: now,
            drawCount: 4
        )
        let stats = PackStats(pack: pack, progress: progress)
        XCTAssertEqual(stats.ownedUniqueCards, 1)
        XCTAssertEqual(stats.remainingUnownedCards, 1)
        XCTAssertEqual(stats.totalPossiblePairs, 6)
        XCTAssertEqual(stats.ownedUniquePairs, 1)
        XCTAssertFalse(stats.isCardComplete)
        // 未知の variantId は所持集合には残る。コンプ枚数には既知のバリアントだけを数える。
        XCTAssertEqual(stats.ownedVariants(for: cards[0].id), Set(["common", "not-a-variant"]))
        XCTAssertEqual(stats.lastObtainedAt(for: cards[0].id), now.addingTimeInterval(5))
    }
}
