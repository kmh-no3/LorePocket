import Foundation

enum WorldQuotesImport {
    static let packId = "world-quotes-365"

    struct ImportFailure: Equatable, CustomStringConvertible {
        var fileName: String
        var reason: String
        var description: String { "\(fileName): \(reason)" }
    }

    struct BuiltPack: Equatable {
        var pack: Pack
        var analyses: [String: CardAnalysis]
        var failures: [ImportFailure]
    }

    enum ImportError: LocalizedError, Equatable {
        case noCards(failures: [ImportFailure])

        var errorDescription: String? {
            switch self {
            case .noCards(let failures):
                let details = failures.map(\.description)
                return (["カードを1枚も作れませんでした。"] + details).joined(separator: "\n")
            }
        }
    }

    static func makePack(fromMarkdownFiles fileURLs: [URL]) throws -> Pack {
        try build(fromMarkdownFiles: fileURLs).pack
    }

    static func build(fromMarkdownFiles fileURLs: [URL]) throws -> BuiltPack {
        var cards: [Card] = []
        var analyses: [String: CardAnalysis] = [:]
        var failures: [ImportFailure] = []

        for url in fileURLs {
            let fileName = url.lastPathComponent
            let markdown: String
            do {
                markdown = try String(contentsOf: url, encoding: .utf8)
            } catch {
                failures.append(ImportFailure(fileName: fileName, reason: "UTF-8として読めませんでした。"))
                continue
            }

            switch MarkdownCardParser.parseDetailed(markdown) {
            case .failure(let failure):
                failures.append(ImportFailure(fileName: fileName, reason: failure.reason))
            case .success(let parsed):
                let day = normalizedDay(parsed.day ?? url.deletingPathExtension().lastPathComponent)
                let id = "\(packId)-\(day)"
                let card = Card(
                    id: id,
                    genre: parsed.genre,
                    text: parsed.text,
                    person: parsed.person,
                    background: parsed.background,
                    topics: parsed.topics,
                    kind: parsed.kind,
                    sourceTitle: parsed.sourceTitle,
                    longForm: parsed.longForm,
                    sections: parsed.sections
                )
                cards.append(card)
                let analysis = CardAnalysis(
                    citation: parsed.citation,
                    workBackground: parsed.workBackground,
                    commentary: parsed.aiCommentary,
                    updatedAt: nil
                )
                if !analysis.isEmpty {
                    analyses[id] = analysis
                }
            }
        }

        guard !cards.isEmpty else {
            throw ImportError.noCards(failures: failures)
        }

        cards.sort { $0.id < $1.id }

        let meta = PackMeta(
            packId: packId,
            title: "教養としての世界の格言365",
            version: "private-0.1",
            language: "ja",
            description: "ローカルに取り込んだMarkdown（001.md〜）から生成された私的パック。",
            cardCount: cards.count,
            tags: ["quotes", "private"],
            legal: .init(source: "private", redistribution: "disallowed")
        )

        return BuiltPack(
            pack: Pack(meta: meta, cards: cards, variants: PackStorage.defaultVariants()),
            analyses: analyses,
            failures: failures
        )
    }

    static func normalizedDay(_ s: String) -> String {
        let digits = s.trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { $0.isNumber }
        if let n = Int(digits) {
            return String(format: "%03d", n)
        }
        return "000"
    }
}
