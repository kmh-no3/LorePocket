import Foundation
import Observation

@Observable
final class CollectionViewModel {

    let pack: Pack
    let store: ProgressStore

    var query: String = ""
    var sort: SortOption = .obtainedDesc
    var ownership: CollectionOwnership = .all

    private(set) var items: [CardListItem] = []

    enum SortOption: String, CaseIterable, Identifiable {
        case obtainedDesc = "New"
        case rarityDesc = "Rarity"
        case nameAsc = "Name"
        var id: String { rawValue }
    }

    init(pack: Pack, store: ProgressStore) {
        self.pack = pack
        self.store = store
        buildItems()
    }

    var packTitle: String { pack.meta.title }
    var totalCount: Int { pack.cards.count }

    private var stats: PackStats { PackStats(pack: pack, progress: store.progress(for: pack.id)) }
    var ownedCount: Int { stats.ownedUniqueCards }

    var filteredItems: [CardListItem] {
        sortedItems.filter { item in
            guard CollectionQuery.includes(isOwned: item.isOwned, ownership: ownership) else { return false }
            guard let card = pack.cards.first(where: { $0.id == item.cardId }) else { return false }
            return CollectionQuery.matches(card: card, isOwned: item.isOwned, query: query)
        }
    }

    private var sortedItems: [CardListItem] {
        switch sort {
        case .obtainedDesc:
            return items.sorted { a, b in
                let dateA = stats.lastObtainedAt(for: a.cardId) ?? .distantPast
                let dateB = stats.lastObtainedAt(for: b.cardId) ?? .distantPast
                if dateA != dateB { return dateA > dateB }
                return a.cardId < b.cardId
            }
        case .rarityDesc:
            return items.sorted { a, b in
                let rA = a.topRarity ?? .common
                let rB = b.topRarity ?? .common
                if rA != rB { return rA > rB }
                return a.cardId < b.cardId
            }
        case .nameAsc:
            return items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    var progressText: String {
        let percent = totalCount == 0 ? 0 : Int(Double(ownedCount) / Double(totalCount) * 100)
        return "\(ownedCount)/\(totalCount) (\(percent)%)"
    }

    func refresh() {
        buildItems()
    }

    func toggleFavorite(cardId: String) {
        let current = store.isFavorite(packId: pack.id, cardId: cardId)
        store.setFavorite(packId: pack.id, cardId: cardId, isFavorite: !current)
        refresh()
    }

    private func buildItems() {
        let progress = store.progress(for: pack.id)
        let stats = PackStats(pack: pack, progress: progress)
        let now = Date()
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now

        items = pack.cards.map { card in
            let isOwned = stats.ownedCardIds.contains(card.id)
            let topRarity: Rarity? = {
                guard isOwned else { return nil }
                let ownedVariantIds = stats.ownedVariants(for: card.id)
                let rarities = ownedVariantIds.compactMap { variantId -> Rarity? in
                    guard let v = pack.variants.first(where: { $0.variantId == variantId }) else { return nil }
                    return Rarity(variantRarity: v.rarity)
                }
                return rarities.max()
            }()
            let isNew = isOwned && (stats.lastObtainedAt(for: card.id) ?? .distantPast) > oneDayAgo

            return CardListItem(
                cardId: card.id,
                title: isOwned ? card.person : "???",
                subtitle: card.genre.isEmpty ? "" : card.genre.joined(separator: " / "),
                isOwned: isOwned,
                topRarity: topRarity,
                isFavorite: progress.favoriteCardIds.contains(card.id),
                isNew: isNew
            )
        }
    }
}
