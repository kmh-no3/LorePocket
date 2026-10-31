import XCTest
@testable import LorePocketCore

struct SplitMix64: RandomNumberGenerator {
    var state: UInt64

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

enum EngineFixtures {
    static func card(id: String, text: String = "短いテスト文") -> Card {
        Card(
            id: id,
            genre: ["試験"],
            text: text,
            person: "架空の人",
            background: "テスト用の背景です。",
            topics: ["test"]
        )
    }

    static func pack(
        id: String = "sample-pack-001",
        cards: [Card],
        variants: [Variant]? = nil,
        title: String = "Test Pack"
    ) -> Pack {
        let resolved = variants ?? PackStorage.defaultVariants()
        let meta = PackMeta(
            packId: id,
            title: title,
            version: "1.0.0",
            language: "ja",
            description: "fixture",
            cardCount: cards.count,
            tags: ["test"],
            legal: .init(source: "public", redistribution: "allowed")
        )
        return Pack(meta: meta, cards: cards, variants: resolved)
    }

    static func tokyoCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 9 * 60 * 60)!
        return calendar
    }

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("lorepocket-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
