import XCTest
@testable import LorePocketCore

final class CardModelTests: XCTestCase {
    func testLegacyCardJSONKeepsTextAndDefaultsKind() throws {
        let json = """
        [
          {
            "id": "sample-pack-001-001",
            "genre": ["哲学"],
            "text": "Always carry a notebook.",
            "person": "Sample Author",
            "background": "思いつきを逃さないための小さな習慣。",
            "topics": ["habit", "learning"]
          }
        ]
        """.data(using: .utf8)!

        let cards = try CardCoding.decodeCards(json)
        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].text, "Always carry a notebook.")
        XCTAssertEqual(cards[0].kind, .proverb)
        XCTAssertNil(cards[0].sourceTitle)
        XCTAssertNil(cards[0].longForm)
        XCTAssertTrue(cards[0].sections.isEmpty)
        XCTAssertEqual(cards[0].readingBlocks.map(\.title), ["格言", "背景"])
    }

    func testMissingPersonDoesNotDropTheCard() throws {
        let json = """
        [{"id":"p-1","text":"本文だけ残す。"}]
        """.data(using: .utf8)!
        let cards = try CardCoding.decodeCards(json)
        XCTAssertEqual(cards[0].text, "本文だけ残す。")
        XCTAssertEqual(cards[0].person, "")
        XCTAssertEqual(cards[0].genre, [])
    }

    func testUnknownKindBecomesOtherAndKeepsBody() throws {
        let json = """
        [{
          "id":"hist-1",
          "text":"架空の出来事。",
          "kind":"seasonal",
          "longForm":"季節限定ではなく、未知の種別として残す。"
        }]
        """.data(using: .utf8)!
        let card = try XCTUnwrap(CardCoding.decodeCards(json).first)
        XCTAssertEqual(card.kind, .other)
        XCTAssertEqual(card.text, "架空の出来事。")
        XCTAssertEqual(card.longForm, "季節限定ではなく、未知の種別として残す。")
    }

    func testExtendedCardRoundTripsThroughPackStorage() throws {
        let directory = try EngineFixtures.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let longForm = String(repeating: "これは架空の解説です。", count: 100)
        XCTAssertGreaterThanOrEqual(longForm.count, 1000)
        XCTAssertLessThanOrEqual(longForm.count, 1500)

        let card = Card(
            id: "history-pack-001",
            genre: ["歴史"],
            text: "架空の都市は川のそばにできた。",
            person: "架空の記録",
            background: "短い背景。",
            topics: ["city", "river"],
            kind: .history,
            sourceTitle: "架空史",
            longForm: longForm,
            sections: [CardSection(id: "s1", heading: "補足", body: "川幅は記録によって違う。")]
        )
        let pack = EngineFixtures.pack(id: "history-pack", cards: [card], title: "History")
        try PackStorage.savePack(pack, base: directory)
        let loaded = try PackStorage.loadPack(packId: "history-pack", base: directory)
        XCTAssertEqual(loaded.cards, [card])
        XCTAssertEqual(loaded.cards[0].readingBlocks.map(\.title), ["格言", "作品", "背景", "解説", "補足"])
        XCTAssertEqual(loaded.cards[0].longForm, longForm)
    }

    func testLegacyFileOnDiskStillLoads() throws {
        let directory = try EngineFixtures.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let packDir = try PackStorage.packDirectory(packId: "old-pack", base: directory)
        try FileManager.default.createDirectory(at: packDir, withIntermediateDirectories: true)
        let meta = """
        {"packId":"old-pack","title":"Old","version":"1","language":"ja","description":"old","cardCount":9,"tags":[],"legal":{"source":"private","redistribution":"disallowed"}}
        """
        let cards = """
        [{"id":"old-pack-001","genre":["学習"],"text":"旧形式の短い文。","person":"誰か","background":"背景","topics":["old"]}]
        """
        try meta.write(to: packDir.appendingPathComponent("pack.json"), atomically: true, encoding: .utf8)
        try cards.write(to: packDir.appendingPathComponent("cards.json"), atomically: true, encoding: .utf8)

        let loaded = try PackStorage.loadPack(packId: "old-pack", base: directory)
        XCTAssertEqual(loaded.meta.cardCount, 1)
        XCTAssertEqual(loaded.cards[0].text, "旧形式の短い文。")
        XCTAssertEqual(loaded.cards[0].kind, .proverb)
        XCTAssertEqual(loaded.variants.count, 3)
    }

    func testSampleCardsStayProverbs() {
        XCTAssertTrue(SamplePacks.samplePack.cards.allSatisfy { $0.kind == .proverb && $0.longForm == nil })
    }
}
