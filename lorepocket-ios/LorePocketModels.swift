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

struct Card: Codable, Hashable, Identifiable {
    let id: String
    let genre: [String]
    let text: String
    let person: String
    let background: String
    let topics: [String]
}

struct Variant: Codable, Hashable, Identifiable {
    let variantId: String
    let name: String
    let rarity: String
    let weight: Int
    
    var id: String { variantId }
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
}

struct ProgressRoot: Codable, Hashable {
    var packs: [String: PackProgress] = [:]
}


