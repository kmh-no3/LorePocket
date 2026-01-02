import Foundation

enum DrawEngine {
    enum DrawError: Error, Hashable {
        case emptyCards
        case emptyVariants
    }
    
    struct DrawResult: Hashable, Identifiable {
        let card: Card
        let variant: Variant
        let ownedCard: OwnedCard
        let wasNewCard: Bool
        let wasNewVariantForCard: Bool
        
        var id: String {
            "\(ownedCard.id)::\(ownedCard.obtainedAt.timeIntervalSince1970)"
        }
    }
    
    static func draw<R: RandomNumberGenerator>(
        pack: Pack,
        progress: PackProgress,
        now: Date = Date(),
        rng: inout R
    ) throws -> DrawResult {
        guard !pack.cards.isEmpty else { throw DrawError.emptyCards }
        guard !pack.variants.isEmpty else { throw DrawError.emptyVariants }
        
        let ownedByCard = Dictionary(grouping: progress.owned, by: { $0.cardId })
        let ownedCardIds = Set(ownedByCard.keys)
        
        let unownedCards = pack.cards.filter { !ownedCardIds.contains($0.id) }
        let selectedCard: Card
        let wasNewCard: Bool
        if let c = unownedCards.randomElement(using: &rng) {
            selectedCard = c
            wasNewCard = true
        } else {
            // 全カード所持後は「未所持バリアントが残っているカード」を優先して抽選する
            let variantTotal = pack.variants.count
            let candidates = pack.cards.filter { card in
                let ownedVariants = Set((ownedByCard[card.id] ?? []).map(\.variantId))
                return ownedVariants.count < variantTotal
            }
            selectedCard = (candidates.randomElement(using: &rng) ?? pack.cards.randomElement(using: &rng))!
            wasNewCard = false
        }
        
        let ownedVariantsForCard = Set((ownedByCard[selectedCard.id] ?? []).map { $0.variantId })
        let unownedVariants = pack.variants.filter { !ownedVariantsForCard.contains($0.variantId) }
        
        let selectedVariant: Variant
        let wasNewVariantForCard: Bool
        if let v = weightedPick(unownedVariants, rng: &rng) {
            selectedVariant = v
            wasNewVariantForCard = true
        } else {
            selectedVariant = weightedPick(pack.variants, rng: &rng) ?? pack.variants.first!
            wasNewVariantForCard = !ownedVariantsForCard.contains(selectedVariant.variantId)
        }
        
        let owned = OwnedCard(cardId: selectedCard.id, variantId: selectedVariant.variantId, obtainedAt: now)
        return .init(
            card: selectedCard,
            variant: selectedVariant,
            ownedCard: owned,
            wasNewCard: wasNewCard,
            wasNewVariantForCard: wasNewVariantForCard
        )
    }
    
    private static func weightedPick<T, R: RandomNumberGenerator>(
        _ items: [T],
        weight: (T) -> Int = { _ in 1 },
        rng: inout R
    ) -> T? {
        guard !items.isEmpty else { return nil }
        let weights = items.map { max(0, weight($0)) }
        let total = weights.reduce(0, +)
        guard total > 0 else { return items.randomElement(using: &rng) }
        
        var roll = Int.random(in: 0..<total, using: &rng)
        for (idx, w) in weights.enumerated() {
            if roll < w { return items[idx] }
            roll -= w
        }
        return items.last
    }
}

private extension DrawEngine {
    static func weightedPick<R: RandomNumberGenerator>(_ variants: [Variant], rng: inout R) -> Variant? {
        weightedPick(variants, weight: { $0.weight }, rng: &rng)
    }
}


