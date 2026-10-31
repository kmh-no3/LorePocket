import Foundation

/// 旧 `cards.json`（格言フィールドのみ）と拡張フィールドの両方を読む。
enum CardCoding {
    enum CodingError: Error, Equatable {
        case notAnArray
    }

    static func decodeCards(_ data: Data) throws -> [Card] {
        let decoder = JSONDecoder()
        do {
            return try decoder.decode([WireCard].self, from: data).map { $0.makeCard() }
        } catch let error as DecodingError {
            throw error
        } catch {
            throw CodingError.notAnArray
        }
    }

    static func decodeCards(from url: URL) throws -> [Card] {
        try decodeCards(Data(contentsOf: url))
    }
}

private struct WireCard: Decodable {
    let id: String
    var genre: [String]?
    let text: String
    var person: String?
    var background: String?
    var topics: [String]?
    var kind: String?
    var sourceTitle: String?
    var longForm: String?
    var sections: [CardSection]?

    func makeCard() -> Card {
        let resolvedKind: CardKind
        if let kind {
            resolvedKind = CardKind(rawValue: kind) ?? .other
        } else {
            resolvedKind = .proverb
        }
        return Card(
            id: id,
            genre: genre ?? [],
            text: text,
            person: person ?? "",
            background: background ?? "",
            topics: topics ?? [],
            kind: resolvedKind,
            sourceTitle: sourceTitle,
            longForm: longForm,
            sections: sections ?? []
        )
    }
}
