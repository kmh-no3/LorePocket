import XCTest
@testable import LorePocketCore

final class ProgressFileGuardTests: XCTestCase {
    func testMissingFileCanBeCreatedLater() throws {
        let directory = try EngineFixtures.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        var session = ProgressSession.open(url: url)
        XCTAssertTrue(session.writesEnabled)
        XCTAssertNil(session.loadWarning)
        let owned = OwnedCard(cardId: "sample-pack-001-001", variantId: "common", obtainedAt: Date(timeIntervalSince1970: 10))
        session.record(packId: "sample-pack-001", ownedCard: owned)
        try session.persist(to: url)
        XCTAssertEqual(try ProgressCoding.load(from: url).packs["sample-pack-001"]?.owned, [owned])
    }

    func testLegacyFileStaysWritable() throws {
        let directory = try EngineFixtures.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let json = """
        {"packs":{"sample-pack-001":{"owned":[{"cardId":"sample-pack-001-001","variantId":"common","obtainedAt":"2026-01-01T00:00:00Z"}]}}}
        """
        try json.write(to: url, atomically: true, encoding: .utf8)
        let session = ProgressSession.open(url: url)
        XCTAssertTrue(session.writesEnabled)
        XCTAssertEqual(session.root.packs["sample-pack-001"]?.owned.count, 1)
        XCTAssertNil(session.loadWarning)
    }

    func testCorruptFileIsCopiedAndNotReplacedUntilReset() throws {
        let directory = try EngineFixtures.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("progress.json")
        let original = Data("{\"packs\":".utf8)
        try original.write(to: url)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        var session = ProgressSession.open(url: url, now: now)
        XCTAssertFalse(session.writesEnabled)
        XCTAssertNotNil(session.loadWarning)
        XCTAssertTrue(session.root.packs.isEmpty)
        XCTAssertEqual(try Data(contentsOf: url), original)

        let quarantine = try XCTUnwrap(session.quarantineURL)
        XCTAssertEqual(try Data(contentsOf: quarantine), original)
        XCTAssertTrue(quarantine.lastPathComponent.contains("1700000000"))

        session.record(
            packId: "sample-pack-001",
            ownedCard: OwnedCard(cardId: "sample-pack-001-001", variantId: "common", obtainedAt: now)
        )
        try session.persist(to: url)
        XCTAssertEqual(try Data(contentsOf: url), original)

        session.resetAll()
        try session.persist(to: url)
        let replaced = try ProgressCoding.load(from: url)
        XCTAssertTrue(replaced.packs.isEmpty)
        XCTAssertEqual(try Data(contentsOf: quarantine), original)
    }
}
