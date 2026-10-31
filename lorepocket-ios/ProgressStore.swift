import Foundation
import Observation

@MainActor
@Observable
final class ProgressStore {
    private(set) var root: ProgressRoot
    private(set) var loadWarning: String?

    private var writesEnabled: Bool
    private let fileURL: URL

    init(filename: String = "progress.json", directory: URL? = nil) {
        let directory = directory ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = directory.appendingPathComponent(filename)
        let session = ProgressSession.open(url: fileURL)
        self.root = session.root
        self.writesEnabled = session.writesEnabled
        self.loadWarning = session.loadWarning
    }

    func progress(for packId: String) -> PackProgress {
        ProgressBook.progress(in: root, packId: packId)
    }

    func canDrawToday(packId: String, calendar: Calendar = .current) -> Bool {
        ProgressBook.canDraw(
            lastDrawDate: progress(for: packId).lastDrawDate,
            now: Date(),
            calendar: calendar
        )
    }

    func recordDraw(packId: String, ownedCard: OwnedCard) {
        ProgressBook.recordDraw(root: &root, packId: packId, ownedCard: ownedCard)
        persist()
    }

    func isFavorite(packId: String, cardId: String) -> Bool {
        ProgressBook.isFavorite(root: root, packId: packId, cardId: cardId)
    }

    func setFavorite(packId: String, cardId: String, isFavorite: Bool) {
        ProgressBook.setFavorite(root: &root, packId: packId, cardId: cardId, isFavorite: isFavorite)
        persist()
    }

    func reflection(packId: String, cardId: String) -> CardReflection? {
        ProgressBook.reflection(in: root, packId: packId, cardId: cardId)
    }

    func setReflection(packId: String, cardId: String, body: String, now: Date = Date()) {
        ProgressBook.setReflection(root: &root, packId: packId, cardId: cardId, body: body, now: now)
        persist()
    }

    func analysis(packId: String, cardId: String) -> CardAnalysis? {
        ProgressBook.analysis(in: root, packId: packId, cardId: cardId)
    }

    func setAnalysis(packId: String, cardId: String, analysis: CardAnalysis) {
        ProgressBook.setAnalysis(root: &root, packId: packId, cardId: cardId, analysis: analysis)
        persist()
    }

    func resetAll() {
        ProgressBook.resetAll(root: &root)
        writesEnabled = true
        loadWarning = nil
        persist()
    }

    private func persist() {
        var session = ProgressSession(
            root: root,
            writesEnabled: writesEnabled,
            loadWarning: loadWarning,
            quarantineURL: nil
        )
        do {
            try session.persist(to: fileURL)
        } catch {
            // 書き込み不能でもメモリ上の所持は残す。壊れたファイルは writesEnabled が false の間は触らない。
        }
    }
}
