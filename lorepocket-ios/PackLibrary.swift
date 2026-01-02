import Foundation
import Observation

@MainActor
@Observable
final class PackLibrary {
    private(set) var packs: [Pack] = []
    
    init() {
        reload()
    }
    
    func reload() {
        let imported = PackStorage.loadAllPacks()
        // サンプルは常に表示（公開用）
        self.packs = [SamplePacks.samplePack] + imported
    }
    
    func importWorldQuotesMarkdown(fileURLs: [URL]) throws {
        let pack = try WorldQuotesImport.makePack(fromMarkdownFiles: fileURLs)
        try PackStorage.savePack(pack)
        reload()
    }
}


