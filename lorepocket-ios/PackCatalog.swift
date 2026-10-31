import Foundation

/// `PackLibrary` の中身。サンプルパックは常に先頭で、取り込み結果を後ろに続ける。
enum PackCatalog {
    static func displayedPacks(imported: [Pack]) -> [Pack] {
        [SamplePacks.samplePack] + imported
    }

    struct MarkdownImportReport: Equatable {
        var packID: String
        var failures: [WorldQuotesImport.ImportFailure]
        var analyses: [String: CardAnalysis]
    }

    @discardableResult
    static func importWorldQuotesMarkdown(fileURLs: [URL], base: URL?) throws -> MarkdownImportReport {
        let built = try WorldQuotesImport.build(fromMarkdownFiles: fileURLs)
        try PackStorage.savePack(built.pack, base: base)
        return MarkdownImportReport(packID: built.pack.id, failures: built.failures, analyses: built.analyses)
    }
}
