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
}
