import XCTest
@testable import LorePocketCore

final class ProgressStoreTests: XCTestCase {
    func testCanDrawWhenThePackHasNeverBeenDrawn() {
        let calendar = EngineFixtures.tokyoCalendar()
        let now = EngineFixtures.date(2026, 10, 31, 21, 0, calendar: calendar)
        XCTAssertTrue(ProgressBook.canDraw(lastDrawDate: nil, now: now, calendar: calendar))
    }

    func testSameTokyoCalendarDayBlocksAndNextDayAllows() {
        let calendar = EngineFixtures.tokyoCalendar()
        let morning = EngineFixtures.date(2026, 10, 31, 0, 30, calendar: calendar)
        let night = EngineFixtures.date(2026, 10, 31, 23, 30, calendar: calendar)
        let nextMorning = EngineFixtures.date(2026, 11, 1, 0, 10, calendar: calendar)

        XCTAssertFalse(ProgressBook.canDraw(lastDrawDate: morning, now: night, calendar: calendar))
        XCTAssertTrue(ProgressBook.canDraw(lastDrawDate: night, now: nextMorning, calendar: calendar))
    }

    func testRecordDrawKeepsTheCardAndDoesNotDuplicateThePair() {
        var root = ProgressRoot()
        let owned = OwnedCard(
            cardId: "sample-pack-001-001",
            variantId: "common",
            obtainedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let other = OwnedCard(
            cardId: "other-pack-001",
            variantId: "foil",
            obtainedAt: owned.obtainedAt
        )
        ProgressBook.recordDraw(root: &root, packId: "other", ownedCard: other)
        ProgressBook.recordDraw(root: &root, packId: "sample-pack-001", ownedCard: owned)
        ProgressBook.recordDraw(root: &root, packId: "sample-pack-001", ownedCard: owned)

        XCTAssertEqual(root.packs["sample-pack-001"]?.owned, [owned])
        XCTAssertEqual(root.packs["sample-pack-001"]?.drawCount, 2)
        XCTAssertEqual(root.packs["sample-pack-001"]?.lastDrawDate, owned.obtainedAt)
        XCTAssertEqual(root.packs["other"]?.owned, [other])
    }

    func testLegacyJSONWithoutDrawCountKeepsOwnedCards() throws {
        let json = """
        {
          "packs": {
            "sample-pack-001": {
              "lastDrawDate": "2026-01-01T00:00:00Z",
              "owned": [
                {
                  "cardId": "sample-pack-001-001",
                  "variantId": "common",
                  "obtainedAt": "2026-01-01T00:00:00Z"
                }
              ]
            }
          }
        }
        """.data(using: .utf8)!

        let root = try ProgressCoding.decode(json)
        let progress = root.packs["sample-pack-001"]
        XCTAssertEqual(progress?.owned.count, 1)
        XCTAssertEqual(progress?.owned.first?.cardId, "sample-pack-001-001")
        XCTAssertEqual(progress?.owned.first?.variantId, "common")
        XCTAssertEqual(progress?.drawCount, 0)
        XCTAssertNotNil(progress?.lastDrawDate)
    }

    func testUnknownKeysDoNotDropOwnedCards() throws {
        let json = """
        {
          "packs": {
            "sample-pack-001": {
              "drawCount": 3,
              "futureField": true,
              "owned": [
                {
                  "cardId": "sample-pack-001-004",
                  "variantId": "legend",
                  "obtainedAt": "2026-04-02T03:04:05Z",
                  "note": "ignore"
                }
              ]
            }
          },
          "albums": []
        }
        """.data(using: .utf8)!

        let root = try ProgressCoding.decode(json)
        XCTAssertEqual(root.packs["sample-pack-001"]?.owned.count, 1)
        XCTAssertEqual(root.packs["sample-pack-001"]?.drawCount, 3)
        XCTAssertEqual(root.packs["sample-pack-001"]?.owned.first?.variantId, "legend")
    }

    func testRoundTripPreservesOwnedCards() throws {
        var root = ProgressRoot()
        let owned = OwnedCard(
            cardId: "sample-pack-001-002",
            variantId: "foil",
            obtainedAt: Date(timeIntervalSince1970: 1_767_225_600)
        )
        ProgressBook.recordDraw(root: &root, packId: "sample-pack-001", ownedCard: owned)
        let decoded = try ProgressCoding.decode(try ProgressCoding.encode(root))
        XCTAssertEqual(decoded, root)
    }

    func testCorruptJSONThrowsAndFileRoundTrip() throws {
        XCTAssertThrowsError(try ProgressCoding.decode(Data("{\"packs\":".utf8)))

        let directory = try EngineFixtures.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        var root = ProgressRoot()
        let owned = OwnedCard(
            cardId: "sample-pack-001-001",
            variantId: "common",
            obtainedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        ProgressBook.recordDraw(root: &root, packId: "sample-pack-001", ownedCard: owned)
        let url = directory.appendingPathComponent("progress.json")
        try ProgressCoding.save(root, to: url)
        XCTAssertEqual(try ProgressCoding.load(from: url), root)
    }

    func testDrawThenRecordBlocksThatDayAndKeepsTheCard() throws {
        let calendar = EngineFixtures.tokyoCalendar()
        let now = EngineFixtures.date(2026, 10, 31, 8, 0, calendar: calendar)
        let tomorrow = EngineFixtures.date(2026, 11, 1, 8, 0, calendar: calendar)
        let pack = SamplePacks.samplePack
        var root = ProgressRoot()

        var rng = SplitMix64(state: 4)
        let first = try DrawEngine.draw(
            pack: pack,
            progress: ProgressBook.progress(in: root, packId: pack.id),
            now: now,
            rng: &rng
        )
        ProgressBook.recordDraw(root: &root, packId: pack.id, ownedCard: first.ownedCard)

        XCTAssertFalse(ProgressBook.canDraw(
            lastDrawDate: root.packs[pack.id]?.lastDrawDate,
            now: now,
            calendar: calendar
        ))
        XCTAssertTrue(ProgressBook.canDraw(
            lastDrawDate: root.packs[pack.id]?.lastDrawDate,
            now: tomorrow,
            calendar: calendar
        ))

        var rng2 = SplitMix64(state: 11)
        _ = try DrawEngine.draw(
            pack: pack,
            progress: ProgressBook.progress(in: root, packId: pack.id),
            now: tomorrow,
            rng: &rng2
        )
        let secondOwned = OwnedCard(cardId: "sample-pack-001-009", variantId: "common", obtainedAt: tomorrow)
        ProgressBook.recordDraw(root: &root, packId: pack.id, ownedCard: secondOwned)

        let owned = root.packs[pack.id]?.owned ?? []
        XCTAssertTrue(owned.contains(where: { $0.cardId == first.ownedCard.cardId && $0.variantId == first.ownedCard.variantId }))
        XCTAssertTrue(owned.contains(secondOwned))
        XCTAssertEqual(root.packs[pack.id]?.drawCount, 2)
    }
}
