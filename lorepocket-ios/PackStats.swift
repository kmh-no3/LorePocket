import Foundation

struct PackStats: Hashable {
    let pack: Pack
    let progress: PackProgress
    
    var totalCards: Int { pack.cards.count }
    var totalVariants: Int { pack.variants.count }
    
    var ownedCardIds: Set<String> {
        Set(progress.owned.map(\.cardId)).intersection(Set(pack.cards.map(\.id)))
    }
    
    var ownedUniqueCards: Int { ownedCardIds.count }
    
    var ownedPairs: Set<String> {
        let variantIds = Set(pack.variants.map(\.variantId))
        let cardIds = Set(pack.cards.map(\.id))
        return Set(progress.owned.compactMap { oc -> String? in
            guard cardIds.contains(oc.cardId), variantIds.contains(oc.variantId) else { return nil }
            return "\(oc.cardId)::\(oc.variantId)"
        })
    }
    
    var totalPossiblePairs: Int { totalCards * totalVariants }
    var ownedUniquePairs: Int { ownedPairs.count }
    
    var cardCompletion: Double {
        guard totalCards > 0 else { return 0 }
        return Double(ownedUniqueCards) / Double(totalCards)
    }
    
    var variantCompletion: Double {
        guard totalPossiblePairs > 0 else { return 0 }
        return Double(ownedUniquePairs) / Double(totalPossiblePairs)
    }
    
    func ownedVariants(for cardId: String) -> Set<String> {
        Set(progress.owned.filter { $0.cardId == cardId }.map(\.variantId))
    }
    
    func lastObtainedAt(for cardId: String) -> Date? {
        progress.owned
            .filter { $0.cardId == cardId }
            .map(\.obtainedAt)
            .max()
    }
    
    func missingVariantCount(for cardId: String) -> Int {
        max(0, totalVariants - ownedVariants(for: cardId).count)
    }
    
    var remainingUnownedCards: Int {
        max(0, totalCards - ownedUniqueCards)
    }
    
    var remainingVariantPairs: Int {
        max(0, totalPossiblePairs - ownedUniquePairs)
    }
    
    var isCardComplete: Bool { remainingUnownedCards == 0 }
    var isVariantComplete: Bool { remainingVariantPairs == 0 }
}


