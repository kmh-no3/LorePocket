import XCTest
@testable import LorePocketCore

final class DrawEngineTests: XCTestCase {
    func testEmptyCardsThrows() {
        var rng = SplitMix64(state: 1)
        let pack = EngineFixtures.pack(cards: [])
        XCTAssertThrowsError(try DrawEngine.draw(pack: pack, progress: PackProgress(), rng: &rng)) { error in
            XCTAssertEqual(error as? DrawEngine.DrawError, .emptyCards)
        }
    }

    func testEmptyVariantsThrows() {
        var rng = SplitMix64(state: 1)
        let pack = EngineFixtures.pack(
            cards: [EngineFixtures.card(id: "sample-pack-001-001")],
            variants: []
        )
        XCTAssertThrowsError(try DrawEngine.draw(pack: pack, progress: PackProgress(), rng: &rng)) { error in
            XCTAssertEqual(error as? DrawEngine.DrawError, .emptyVariants)
        }
    }

    func testUnownedCardIsChosenWhileAnyRemain() throws {
        let cards = [
            EngineFixtures.card(id: "sample-pack-001-001"),
            EngineFixtures.card(id: "sample-pack-001-002"),
            EngineFixtures.card(id: "sample-pack-001-003"),
        ]
        let pack = EngineFixtures.pack(cards: cards)
        var progress = PackProgress()
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        progress.owned = [
            OwnedCard(cardId: cards[0].id, variantId: "common", obtainedAt: now),
            OwnedCard(cardId: cards[2].id, variantId: "foil", obtainedAt: now),
        ]

        for seed in 1...40 {
            var rng = SplitMix64(state: UInt64(seed))
            let before = progress
            let result = try DrawEngine.draw(pack: pack, progress: progress, now: now, rng: &rng)
            XCTAssertEqual(result.card.id, cards[1].id)
            XCTAssertTrue(result.wasNewCard)
            XCTAssertTrue(result.wasNewVariantForCard)
            XCTAssertEqual(result.ownedCard.cardId, cards[1].id)
            XCTAssertEqual(result.ownedCard.obtainedAt, now)
            XCTAssertEqual(progress, before)
        }
    }

    func testAfterEveryCardIsOwnedMissingVariantsArePreferred() throws {
        let cards = [
            EngineFixtures.card(id: "sample-pack-001-001"),
            EngineFixtures.card(id: "sample-pack-001-002"),
            EngineFixtures.card(id: "sample-pack-001-003"),
        ]
        let pack = EngineFixtures.pack(cards: cards)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        var owned: [OwnedCard] = []
        for card in [cards[0], cards[2]] {
            for variant in pack.variants {
                owned.append(OwnedCard(cardId: card.id, variantId: variant.variantId, obtainedAt: now))
            }
        }
        owned.append(OwnedCard(cardId: cards[1].id, variantId: "common", obtainedAt: now))
        owned.append(OwnedCard(cardId: cards[1].id, variantId: "foil", obtainedAt: now))
        let progress = PackProgress(owned: owned, lastDrawDate: now, drawCount: owned.count)

        for seed in 1...30 {
            var rng = SplitMix64(state: UInt64(seed))
            let result = try DrawEngine.draw(pack: pack, progress: progress, now: now, rng: &rng)
            XCTAssertEqual(result.card.id, cards[1].id)
            XCTAssertEqual(result.variant.variantId, "legend")
            XCTAssertFalse(result.wasNewCard)
            XCTAssertTrue(result.wasNewVariantForCard)
        }
    }

    func testCompletedCollectionStillDrawsWithoutMarkingNew() throws {
        let cards = [EngineFixtures.card(id: "sample-pack-001-001")]
        let pack = EngineFixtures.pack(cards: cards)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let owned = pack.variants.map {
            OwnedCard(cardId: cards[0].id, variantId: $0.variantId, obtainedAt: now)
        }
        let progress = PackProgress(owned: owned, lastDrawDate: now, drawCount: owned.count)

        var rng = SplitMix64(state: 7)
        let result = try DrawEngine.draw(pack: pack, progress: progress, now: now, rng: &rng)
        XCTAssertEqual(result.card.id, cards[0].id)
        XCTAssertFalse(result.wasNewCard)
        XCTAssertFalse(result.wasNewVariantForCard)
        XCTAssertTrue(pack.variants.map(\.variantId).contains(result.variant.variantId))
    }

    func testZeroWeightVariantIsNotChosenWhenAnotherHasWeight() throws {
        let variants = [
            Variant(variantId: "zero", name: "ゼロ", rarity: "common", weight: 0),
            Variant(variantId: "only", name: "のみ", rarity: "rare", weight: 5),
        ]
        let pack = EngineFixtures.pack(
            cards: [EngineFixtures.card(id: "sample-pack-001-001")],
            variants: variants
        )
        for seed in 1...20 {
            var rng = SplitMix64(state: UInt64(seed))
            let result = try DrawEngine.draw(pack: pack, progress: PackProgress(), rng: &rng)
            XCTAssertEqual(result.variant.variantId, "only")
        }
    }

    func testDefaultVariantWeightsStayAtTheDailyRates() {
        let variants = PackStorage.defaultVariants()
        XCTAssertEqual(variants.map(\.variantId), ["common", "foil", "legend"])
        XCTAssertEqual(variants.map(\.weight), [80, 18, 2])
        XCTAssertEqual(SamplePacks.samplePack.variants.map(\.weight), [80, 18, 2])
    }
}
