import Foundation

struct Pack: Hashable, Identifiable {
    let meta: PackMeta
    let cards: [Card]
    let variants: [Variant]
    
    var id: String { meta.packId }
}

struct PackMeta: Codable, Hashable, Identifiable {
    let packId: String
    let title: String
    let version: String
    let language: String
    let description: String
    let cardCount: Int
    let tags: [String]
    
    struct Legal: Codable, Hashable {
        let source: String
        let redistribution: String
    }
    let legal: Legal
    
    var id: String { packId }
}

enum CardKind: String, Codable, CaseIterable, Hashable {
    case proverb
    case book
    case manga
    case novel
    case history
    case person
    case knowledge
    case other
}

struct CardSection: Codable, Hashable, Identifiable {
    var id: String
    var heading: String
    var body: String
}

struct ReadingBlock: Hashable, Identifiable {
    var id: String
    var title: String
    var body: String
}

struct Card: Codable, Hashable, Identifiable {
    let id: String
    let genre: [String]
    let text: String
    let person: String
    let background: String
    let topics: [String]
    var kind: CardKind
    var sourceTitle: String?
    var longForm: String?
    var sections: [CardSection]

    init(
        id: String,
        genre: [String],
        text: String,
        person: String,
        background: String,
        topics: [String],
        kind: CardKind = .proverb,
        sourceTitle: String? = nil,
        longForm: String? = nil,
        sections: [CardSection] = []
    ) {
        self.id = id
        self.genre = genre
        self.text = text
        self.person = person
        self.background = background
        self.topics = topics
        self.kind = kind
        self.sourceTitle = sourceTitle
        self.longForm = longForm
        self.sections = sections
    }

    /// 詳細画面がそのまま並べられる階層。旧カードは格言・背景・Topicsだけになる。
    var readingBlocks: [ReadingBlock] {
        var blocks: [ReadingBlock] = []
        if !text.isEmpty {
            blocks.append(ReadingBlock(id: "text", title: "格言", body: text))
        }
        if let sourceTitle, !sourceTitle.isEmpty {
            blocks.append(ReadingBlock(id: "source", title: "作品", body: sourceTitle))
        }
        if !background.isEmpty {
            blocks.append(ReadingBlock(id: "background", title: "背景", body: background))
        }
        if let longForm, !longForm.isEmpty {
            blocks.append(ReadingBlock(id: "longForm", title: "解説", body: longForm))
        }
        for section in sections where !section.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            blocks.append(ReadingBlock(id: "section-\(section.id)", title: section.heading, body: section.body))
        }
        return blocks
    }
}

struct Variant: Codable, Hashable, Identifiable {
    let variantId: String
    let name: String
    let rarity: String
    let weight: Int
    
    var id: String { variantId }
}

struct CardReflection: Codable, Hashable {
    var body: String
    var updatedAt: Date
}

struct OwnedCard: Codable, Hashable, Identifiable {
    let cardId: String
    let variantId: String
    let obtainedAt: Date
    
    var id: String { "\(cardId)::\(variantId)" }
}

struct PackProgress: Codable, Hashable {
    var owned: [OwnedCard] = []
    var lastDrawDate: Date? = nil
    var drawCount: Int = 0
    var favoriteCardIds: [String] = []
    var reflections: [String: CardReflection] = [:]
}

struct ProgressRoot: Codable, Hashable {
    var packs: [String: PackProgress] = [:]
}

// MARK: - Collection UI

enum Rarity: String, CaseIterable, Comparable {
    case common, rare, epic, legendary

    static func < (lhs: Rarity, rhs: Rarity) -> Bool {
        let order: [Rarity] = [.common, .rare, .epic, .legendary]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }

    init?(variantRarity: String) {
        switch variantRarity.lowercased() {
        case "common": self = .common
        case "rare": self = .rare
        case "epic": self = .epic
        case "legendary": self = .legendary
        default: return nil
        }
    }
}

struct CardListItem: Identifiable, Hashable {
    var id: String { cardId }
    let cardId: String
    let title: String
    let subtitle: String
    let isOwned: Bool
    let topRarity: Rarity?
    let isFavorite: Bool
    let isNew: Bool
}
