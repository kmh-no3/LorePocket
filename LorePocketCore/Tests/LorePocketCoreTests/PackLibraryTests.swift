import XCTest
@testable import LorePocketCore

final class PackLibraryTests: XCTestCase {
    func testSamplePackStaysShortAndIsAlwaysFirst() {
        let pack = SamplePacks.samplePack
        XCTAssertEqual(pack.cards.count, 10)
        XCTAssertEqual(pack.meta.legal.redistribution, "allowed")
        XCTAssertEqual(pack.meta.legal.source, "public")
        for card in pack.cards {
            XCTAssertLessThan(card.text.count, 200)
            XCTAssertTrue(card.id.hasPrefix(pack.id + "-"))
        }

        let imported = EngineFixtures.pack(id: "aaa-pack", cards: [EngineFixtures.card(id: "aaa-pack-001")], title: "AAA")
        let displayed = PackCatalog.displayedPacks(imported: [imported])
        XCTAssertEqual(displayed.map(\.id), [SamplePacks.samplePack.id, "aaa-pack"])
    }

    func testSaveAndLoadFixesCardCountAndFillsMissingVariants() throws {
        let directory = try EngineFixtures.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let card = EngineFixtures.card(id: "local-pack-001")
        let pack = EngineFixtures.pack(id: "local-pack", cards: [card], variants: PackStorage.defaultVariants(), title: "Local")
        let wrongCount = Pack(
            meta: PackMeta(
                packId: pack.id,
                title: "Local",
                version: "1.0.0",
                language: "ja",
                description: "local fixture",
                cardCount: 99,
                tags: ["local"],
                legal: .init(source: "public", redistribution: "allowed")
            ),
            cards: pack.cards,
            variants: pack.variants
        )
        try PackStorage.savePack(wrongCount, base: directory)

        let variantURL = try PackStorage.packDirectory(packId: pack.id, base: directory)
            .appendingPathComponent("variants.json")
        try FileManager.default.removeItem(at: variantURL)
        let cover = try PackStorage.packDirectory(packId: pack.id, base: directory)
            .appendingPathComponent("assets", isDirectory: true)
        try FileManager.default.createDirectory(at: cover, withIntermediateDirectories: true)
        try Data("cover".utf8).write(to: cover.appendingPathComponent("cover.png"))

        let loaded = try PackStorage.loadPack(packId: pack.id, base: directory)
        XCTAssertEqual(loaded.cards.count, 1)
        XCTAssertEqual(loaded.meta.cardCount, 1)
        XCTAssertEqual(loaded.variants.map(\.variantId), ["common", "foil", "legend"])
        let coverData = try Data(contentsOf: cover.appendingPathComponent("cover.png"))
        XCTAssertEqual(coverData, Data("cover".utf8))
    }

    func testLoadAllPacksSortsByTitleAndSkipsJunk() throws {
        let directory = try EngineFixtures.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let zeta = EngineFixtures.pack(id: "zeta", cards: [EngineFixtures.card(id: "zeta-001")], title: "Zeta")
        let alpha = EngineFixtures.pack(id: "alpha", cards: [EngineFixtures.card(id: "alpha-001")], title: "Alpha")
        try PackStorage.savePack(zeta, base: directory)
        try PackStorage.savePack(alpha, base: directory)
        let junk = try PackStorage.packsDirectory(base: directory).appendingPathComponent("junk", isDirectory: true)
        try FileManager.default.createDirectory(at: junk, withIntermediateDirectories: true)
        try Data("nope".utf8).write(to: junk.appendingPathComponent("note.txt"))

        XCTAssertEqual(PackStorage.loadAllPacks(base: directory).map(\.id), ["alpha", "zeta"])
    }

    func testMarkdownImportWritesPackWithoutTouchingProgress() throws {
        let directory = try EngineFixtures.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let progressURL = directory.appendingPathComponent("progress.json")
        try Data("keep-owned-cards".utf8).write(to: progressURL)

        let fileA = directory.appendingPathComponent("002.md")
        let fileB = directory.appendingPathComponent("001.md")
        try markdown(day: "002", text: "二枚目のテスト文。").write(to: fileA, atomically: true, encoding: .utf8)
        try markdown(day: "001", text: "一枚目のテスト文。").write(to: fileB, atomically: true, encoding: .utf8)
        try "not a card".write(to: directory.appendingPathComponent("skip.md"), atomically: true, encoding: .utf8)

        try PackCatalog.importWorldQuotesMarkdown(fileURLs: [fileA, fileB, directory.appendingPathComponent("skip.md")], base: directory)

        let imported = PackStorage.loadAllPacks(base: directory)
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].id, WorldQuotesImport.packId)
        XCTAssertEqual(imported[0].cards.map(\.id), [
            "\(WorldQuotesImport.packId)-001",
            "\(WorldQuotesImport.packId)-002",
        ])
        XCTAssertEqual(imported[0].cards.map(\.text), ["一枚目のテスト文。", "二枚目のテスト文。"])
        XCTAssertEqual(try String(contentsOf: progressURL, encoding: .utf8), "keep-owned-cards")

        let displayed = PackCatalog.displayedPacks(imported: imported)
        XCTAssertEqual(displayed.first?.id, SamplePacks.samplePack.id)
        XCTAssertEqual(displayed.count, 2)
    }

    func testMarkdownParserReadsTheTemplateAndRejectsAnEmptyQuote() throws {
        let parsed = try XCTUnwrap(MarkdownCardParser.parse(markdown: markdown(day: "7", text: "ノートを開いておく。")))
        XCTAssertEqual(parsed.day, "7")
        XCTAssertEqual(parsed.person, "架空の人")
        XCTAssertEqual(parsed.genre, ["試験"])
        XCTAssertEqual(parsed.text, "ノートを開いておく。")
        XCTAssertEqual(parsed.background, "テスト背景。")
        XCTAssertEqual(parsed.topics, ["alpha", "beta"])
        XCTAssertNil(MarkdownCardParser.parse(markdown: "## 格言\n\n"))
        XCTAssertEqual(WorldQuotesImport.normalizedDay("day-7"), "007")
        XCTAssertEqual(WorldQuotesImport.normalizedDay("no-digits"), "000")
    }

    private func markdown(day: String, text: String) -> String {
        """
        ---
        type: proverb
        day: \(day)
        genre:
          - 試験
        person: 架空の人
        ---

        ## 格言
        > \(text)

        ## 人物の解説と、格言が生まれた背景
        テスト背景。

        ## Topics（補足）
        - alpha
        - beta
        """
    }
}
