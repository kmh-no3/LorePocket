import Foundation

enum CollectionOwnership: String, CaseIterable, Hashable {
    case all
    case owned
    case unowned
}

/// 図鑑の絞り込み。未所持カードの本文は検索に出さない。
enum CollectionQuery {
    static func includes(isOwned: Bool, ownership: CollectionOwnership) -> Bool {
        switch ownership {
        case .all: return true
        case .owned: return isOwned
        case .unowned: return !isOwned
        }
    }

    static func matches(card: Card, isOwned: Bool, query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return true }
        var fields = [card.genre.joined(separator: " ")]
        if isOwned {
            fields.append(contentsOf: [
                card.person,
                card.text,
                card.background,
                card.topics.joined(separator: " "),
            ])
        }
        return fields.contains { field in
            field.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    /// 狭い iPhone は2列、それ以上は3列。
    static func columnCount(containerWidth: Double) -> Int {
        containerWidth >= 390 ? 3 : 2
    }
}
