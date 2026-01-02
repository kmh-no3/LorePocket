import Foundation

enum PackStorage {
    enum StorageError: Error {
        case invalidPack
        case cannotRead
    }
    
    static func defaultVariants() -> [Variant] {
        [
            .init(variantId: "common", name: "通常", rarity: "common", weight: 80),
            .init(variantId: "foil", name: "箔押し", rarity: "rare", weight: 18),
            .init(variantId: "legend", name: "レジェンド", rarity: "legendary", weight: 2),
        ]
    }
    
    static func packsDirectory() throws -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("packs", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        return dir
    }
    
    static func packDirectory(packId: String) throws -> URL {
        try packsDirectory().appendingPathComponent(packId, isDirectory: true)
    }
    
    static func loadAllPacks() -> [Pack] {
        do {
            let dir = try packsDirectory()
            let urls = try FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            let packDirs = urls.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            return packDirs.compactMap { try? loadPack(from: $0) }
                .sorted { $0.meta.title < $1.meta.title }
        } catch {
            return []
        }
    }
    
    static func loadPack(packId: String) throws -> Pack {
        try loadPack(from: try packDirectory(packId: packId))
    }
    
    static func savePack(_ pack: Pack) throws {
        let dir = try packDirectory(packId: pack.id)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        
        let metaURL = dir.appendingPathComponent("pack.json")
        let cardsURL = dir.appendingPathComponent("cards.json")
        let variantsURL = dir.appendingPathComponent("variants.json")
        
        try writeJSON(pack.meta, to: metaURL)
        try writeJSON(pack.cards, to: cardsURL)
        try writeJSON(pack.variants, to: variantsURL)
    }
    
    private static func loadPack(from dir: URL) throws -> Pack {
        let metaURL = dir.appendingPathComponent("pack.json")
        let cardsURL = dir.appendingPathComponent("cards.json")
        let variantsURL = dir.appendingPathComponent("variants.json")
        
        let meta: PackMeta = try readJSON(PackMeta.self, from: metaURL)
        let cards: [Card] = try readJSON([Card].self, from: cardsURL)
        
        let variants: [Variant] = (try? readJSON([Variant].self, from: variantsURL)) ?? defaultVariants()
        
        // pack.jsonのcardCountと実体がズレていても、実体を優先する
        let fixedMeta = PackMeta(
            packId: meta.packId,
            title: meta.title,
            version: meta.version,
            language: meta.language,
            description: meta.description,
            cardCount: cards.count,
            tags: meta.tags,
            legal: meta.legal
        )
        
        return Pack(meta: fixedMeta, cards: cards, variants: variants)
    }
    
    private static func jsonEncoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }
    
    private static func jsonDecoder() -> JSONDecoder {
        JSONDecoder()
    }
    
    private static func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try jsonEncoder().encode(value)
        try data.write(to: url, options: [.atomic])
    }
    
    private static func readJSON<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        let data = try Data(contentsOf: url)
        return try jsonDecoder().decode(T.self, from: data)
    }
}


