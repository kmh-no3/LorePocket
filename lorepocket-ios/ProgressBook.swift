import Foundation

/// 所持カードと抽選日の更新規則。UIの `ProgressStore` はこの型へ委譲する。
enum ProgressBook {
    static func progress(in root: ProgressRoot, packId: String) -> PackProgress {
        root.packs[packId] ?? PackProgress()
    }

    static func canDraw(lastDrawDate: Date?, now: Date, calendar: Calendar) -> Bool {
        guard let lastDrawDate else { return true }
        return !calendar.isDate(lastDrawDate, inSameDayAs: now)
    }

    static func recordDraw(root: inout ProgressRoot, packId: String, ownedCard: OwnedCard) {
        var p = progress(in: root, packId: packId)
        if !p.owned.contains(where: { $0.cardId == ownedCard.cardId && $0.variantId == ownedCard.variantId }) {
            p.owned.append(ownedCard)
        }
        p.lastDrawDate = ownedCard.obtainedAt
        p.drawCount += 1
        root.packs[packId] = p
    }

    static func resetAll(root: inout ProgressRoot) {
        root = ProgressRoot()
    }

    static func isFavorite(root: ProgressRoot, packId: String, cardId: String) -> Bool {
        progress(in: root, packId: packId).favoriteCardIds.contains(cardId)
    }

    static func setFavorite(root: inout ProgressRoot, packId: String, cardId: String, isFavorite: Bool) {
        var progress = progress(in: root, packId: packId)
        if isFavorite {
            if !progress.favoriteCardIds.contains(cardId) {
                progress.favoriteCardIds.append(cardId)
            }
        } else {
            progress.favoriteCardIds.removeAll { $0 == cardId }
        }
        root.packs[packId] = progress
    }

    static func reflection(in root: ProgressRoot, packId: String, cardId: String) -> CardReflection? {
        progress(in: root, packId: packId).reflections[cardId]
    }

    static func setReflection(root: inout ProgressRoot, packId: String, cardId: String, body: String, now: Date) {
        var progress = progress(in: root, packId: packId)
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            progress.reflections.removeValue(forKey: cardId)
        } else {
            progress.reflections[cardId] = CardReflection(body: trimmed, updatedAt: now)
        }
        root.packs[packId] = progress
    }

    static func analysis(in root: ProgressRoot, packId: String, cardId: String) -> CardAnalysis? {
        progress(in: root, packId: packId).analyses[cardId]
    }

    static func setAnalysis(root: inout ProgressRoot, packId: String, cardId: String, analysis: CardAnalysis) {
        var progress = progress(in: root, packId: packId)
        if analysis.isEmpty {
            progress.analyses.removeValue(forKey: cardId)
        } else {
            progress.analyses[cardId] = analysis
        }
        root.packs[packId] = progress
    }
}
