import XCTest
@testable import LorePocketCore

final class DrawSessionTests: XCTestCase {
    func testSealedSessionDoesNotDraw() {
        var session = DrawSession()
        var draws = 0
        let outcome = session.handle(.advance, canDraw: true) {
            draws += 1
            return try self.makeResult()
        }
        XCTAssertEqual(draws, 0)
        XCTAssertFalse(outcome.shouldPersist)
        XCTAssertNil(outcome.result)
        XCTAssertEqual(session.phase, .sealed)
    }

    func testStartDrawsAndPersistsOnce() throws {
        var session = DrawSession()
        var draws = 0
        let first = session.handle(.start, canDraw: true) {
            draws += 1
            return try self.makeResult()
        }
        let second = session.handle(.start, canDraw: true) {
            draws += 1
            return try self.makeResult()
        }
        let skipped = session.handle(.skip, canDraw: true) {
            draws += 1
            return try self.makeResult()
        }

        XCTAssertEqual(draws, 1)
        XCTAssertTrue(first.shouldPersist)
        XCTAssertFalse(second.shouldPersist)
        XCTAssertFalse(skipped.shouldPersist)
        XCTAssertEqual(first.result?.ownedCard.cardId, "sample-pack-001-001")
        XCTAssertEqual(second.result?.ownedCard.id, first.result?.ownedCard.id)
        XCTAssertEqual(session.phase, .settled)
        XCTAssertEqual(session.result?.ownedCard.cardId, "sample-pack-001-001")
    }

    func testSkipFromSealedDrawsOnceAndSettles() throws {
        var session = DrawSession()
        var draws = 0
        let outcome = session.handle(.skip, canDraw: true) {
            draws += 1
            return try self.makeResult()
        }
        XCTAssertEqual(draws, 1)
        XCTAssertTrue(outcome.shouldPersist)
        XCTAssertEqual(session.phase, .settled)
    }

    func testBlockedDayDoesNotDraw() {
        var session = DrawSession()
        var draws = 0
        let outcome = session.handle(.start, canDraw: false) {
            draws += 1
            return try self.makeResult()
        }
        XCTAssertEqual(draws, 0)
        XCTAssertTrue(outcome.blocked)
        XCTAssertFalse(outcome.shouldPersist)
        XCTAssertEqual(session.phase, .sealed)
    }

    func testReduceMotionSettlesOnTheFirstStart() throws {
        var session = DrawSession()
        let outcome = session.handle(.start, canDraw: true, reduceMotion: true) {
            try self.makeResult()
        }
        XCTAssertTrue(outcome.shouldPersist)
        XCTAssertEqual(session.phase, .settled)
    }

    func testFailureDoesNotPersistAndCanBeRetried() throws {
        var session = DrawSession()
        var attempts = 0
        let failed = session.handle(.start, canDraw: true) {
            attempts += 1
            throw DrawEngine.DrawError.emptyCards
        }
        XCTAssertEqual(failed.failure, .emptyCards)
        XCTAssertFalse(failed.shouldPersist)
        XCTAssertEqual(session.phase, .sealed)

        let recovered = session.handle(.start, canDraw: true) {
            attempts += 1
            return try self.makeResult()
        }
        XCTAssertEqual(attempts, 2)
        XCTAssertTrue(recovered.shouldPersist)
        XCTAssertEqual(session.phase, .opening)
    }

    func testRecordedDrawBlocksALaterSessionOnTheSameDay() throws {
        let pack = EngineFixtures.pack(cards: [EngineFixtures.card(id: "sample-pack-001-001")])
        let calendar = EngineFixtures.tokyoCalendar()
        let now = EngineFixtures.date(2026, 10, 31, 9, 0, calendar: calendar)
        var root = ProgressRoot()
        var session = DrawSession()
        var rng = SplitMix64(state: 4)

        let outcome = session.handle(.start, canDraw: ProgressBook.canDraw(lastDrawDate: nil, now: now, calendar: calendar)) {
            try DrawEngine.draw(pack: pack, progress: ProgressBook.progress(in: root, packId: pack.id), now: now, rng: &rng)
        }
        XCTAssertTrue(outcome.shouldPersist)
        let result = try XCTUnwrap(outcome.result)
        ProgressBook.recordDraw(root: &root, packId: pack.id, ownedCard: result.ownedCard)

        var again = DrawSession()
        var draws = 0
        let blocked = again.handle(
            .skip,
            canDraw: ProgressBook.canDraw(
                lastDrawDate: ProgressBook.progress(in: root, packId: pack.id).lastDrawDate,
                now: now,
                calendar: calendar
            )
        ) {
            draws += 1
            return try DrawEngine.draw(pack: pack, progress: PackProgress(), now: now, rng: &rng)
        }
        XCTAssertEqual(draws, 0)
        XCTAssertTrue(blocked.blocked)
        XCTAssertEqual(root.packs[pack.id]?.owned.count, 1)
        XCTAssertEqual(root.packs[pack.id]?.drawCount, 1)
    }
}

private extension DrawSessionTests {
    func makeResult() throws -> DrawEngine.DrawResult {
        var rng = SplitMix64(state: 2)
        let pack = EngineFixtures.pack(cards: [EngineFixtures.card(id: "sample-pack-001-001")])
        return try DrawEngine.draw(pack: pack, progress: PackProgress(), now: Date(timeIntervalSince1970: 10), rng: &rng)
    }
}
