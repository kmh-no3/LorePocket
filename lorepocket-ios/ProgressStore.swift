import Foundation
import Observation

@MainActor
@Observable
final class ProgressStore {
    private(set) var root: ProgressRoot
    
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init(filename: String = "progress.json") {
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601
        
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent(filename)
        
        self.root = (try? Self.load(from: fileURL, decoder: decoder)) ?? .init()
    }
    
    func progress(for packId: String) -> PackProgress {
        root.packs[packId] ?? PackProgress()
    }
    
    func canDrawToday(packId: String, calendar: Calendar = .current) -> Bool {
        guard let last = progress(for: packId).lastDrawDate else { return true }
        return !calendar.isDateInToday(last)
    }
    
    func recordDraw(packId: String, ownedCard: OwnedCard) {
        var p = progress(for: packId)
        if !p.owned.contains(where: { $0.cardId == ownedCard.cardId && $0.variantId == ownedCard.variantId }) {
            p.owned.append(ownedCard)
        }
        p.lastDrawDate = ownedCard.obtainedAt
        p.drawCount += 1
        root.packs[packId] = p
        save()
    }
    
    func resetAll() {
        root = .init()
        save()
    }
    
    private func save() {
        do {
            let data = try encoder.encode(root)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            // MVP: UIに出すほどではないので握りつぶし（将来ログ/アラート化）
        }
    }
    
    private static func load(from url: URL, decoder: JSONDecoder) throws -> ProgressRoot {
        let data = try Data(contentsOf: url)
        return try decoder.decode(ProgressRoot.self, from: data)
    }
}


