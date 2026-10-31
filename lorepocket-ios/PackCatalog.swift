import Foundation

/// `PackLibrary` の中身。サンプルパックは常に先頭で、取り込み結果を後ろに続ける。
enum PackCatalog {
    static func displayedPacks(imported: [Pack]) -> [Pack] {
        [SamplePacks.samplePack] + imported
    }

    static func importWorldQuotesMarkdown(fileURLs: [URL], base: URL?) throws {
        let pack = try WorldQuotesImport.makePack(fromMarkdownFiles: fileURLs)
        try PackStorage.savePack(pack, base: base)
    }
}
