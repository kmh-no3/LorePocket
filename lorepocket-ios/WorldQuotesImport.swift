import Foundation

enum WorldQuotesImport {
    static let packId = "world-quotes-365"
    
    static func makePack(fromMarkdownFiles fileURLs: [URL]) throws -> Pack {
        var cards: [Card] = []
        
        for url in fileURLs {
            let md = try String(contentsOf: url, encoding: .utf8)
            guard let parsed = MarkdownCardParser.parse(markdown: md) else { continue }
            
            let day = normalizedDay(parsed.day ?? url.deletingPathExtension().lastPathComponent)
            let id = "\(packId)-\(day)"
            
            let card = Card(
                id: id,
                genre: parsed.genre,
                text: parsed.text,
                person: parsed.person,
                background: parsed.background,
                topics: parsed.topics
            )
            cards.append(card)
        }
        
        // day順（001〜）がある前提でソート
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
        
        return Pack(meta: meta, cards: cards, variants: PackStorage.defaultVariants())
    }
    
    static func normalizedDay(_ s: String) -> String {
        let digits = s.trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { $0.isNumber }
        if let n = Int(digits) {
            return String(format: "%03d", n)
        }
        // どうしても数字が取れない場合のフォールバック
        return "000"
    }
}


