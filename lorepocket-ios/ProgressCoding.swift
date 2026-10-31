import Foundation

/// `progress.json` の読み書き。欠けるキーは既定値にし、未知のキーは捨てない（デコーダが無視する）。
enum ProgressCoding {
    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func encode(_ root: ProgressRoot) throws -> Data {
        try makeEncoder().encode(root)
    }

    static func decode(_ data: Data) throws -> ProgressRoot {
        try makeDecoder().decode(WireRoot.self, from: data).makeRoot()
    }

    static func load(from url: URL) throws -> ProgressRoot {
        try decode(Data(contentsOf: url))
    }

    static func save(_ root: ProgressRoot, to url: URL) throws {
        try encode(root).write(to: url, options: [.atomic])
    }
}

private struct WireRoot: Decodable {
    var packs: [String: WirePackProgress]?

    func makeRoot() -> ProgressRoot {
        var root = ProgressRoot()
        for (id, pack) in packs ?? [:] {
            root.packs[id] = pack.makeProgress()
        }
        return root
    }
}

private struct WirePackProgress: Decodable {
    var owned: [OwnedCard]?
    var lastDrawDate: Date?
    var drawCount: Int?
    var favoriteCardIds: [String]?

    func makeProgress() -> PackProgress {
        var progress = PackProgress()
        progress.owned = owned ?? []
        progress.lastDrawDate = lastDrawDate
        progress.drawCount = drawCount ?? 0
        progress.favoriteCardIds = favoriteCardIds ?? []
        return progress
    }
}
