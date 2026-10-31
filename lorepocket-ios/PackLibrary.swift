import Foundation
import Observation

@MainActor
@Observable
final class PackLibrary {
    private(set) var packs: [Pack] = []

    private let storageBase: URL?

    init(storageBase: URL? = nil) {
        self.storageBase = storageBase
        reload()
    }

    func reload() {
        let imported = PackStorage.loadAllPacks(base: storageBase)
        self.packs = PackCatalog.displayedPacks(imported: imported)
    }

    func importWorldQuotesMarkdown(fileURLs: [URL]) throws {
        try PackCatalog.importWorldQuotesMarkdown(fileURLs: fileURLs, base: storageBase)
        reload()
    }
}
