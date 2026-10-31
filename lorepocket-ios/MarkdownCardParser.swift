import Foundation

enum MarkdownCardParser {
    struct ParseFailure: Error, Equatable, CustomStringConvertible {
        var reason: String
        var description: String { reason }
    }

    struct Parsed: Hashable {
        let day: String?
        let genre: [String]
        let person: String
        let text: String
        let background: String
        let topics: [String]
        var kind: CardKind = .proverb
        var sourceTitle: String? = nil
        var longForm: String? = nil
        var sections: [CardSection] = []
        var citation: String? = nil
        var workBackground: String? = nil
        var aiCommentary: String? = nil
    }

    /// 旧呼び出し。失敗した理由は捨てて nil にする。
    static func parse(markdown: String) -> Parsed? {
        if case .success(let parsed) = parseDetailed(markdown) {
            return parsed
        }
        return nil
    }

    /// LorePocket_spec.md のテンプレに、長文・任意見出し・追加の frontmatter を足して読む。
    static func parseDetailed(_ markdown: String) -> Result<Parsed, ParseFailure> {
        let normalized = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        let (frontmatter, body) = splitFrontmatter(normalized)
        let meta = parseFrontmatter(frontmatter ?? "")
        let blocks = headingBlocks(body)

        func block(matching prefixes: [String]) -> String? {
            blocks.first { heading, _ in
                prefixes.contains { heading.hasPrefix($0) }
            }?.1
        }

        let quoteBlock = block(matching: ["格言"]) ?? ""
        let proseBlock = block(matching: ["本文"]) ?? ""
        let quote = parseQuote(from: quoteBlock).trimmingCharacters(in: .whitespacesAndNewlines)
        let prose = proseBlock.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = quote.isEmpty ? prose : quote
        guard !text.isEmpty else {
            return .failure(ParseFailure(reason: "「## 格言」または「## 本文」の本文が空です。"))
        }

        let background = (block(matching: ["人物の解説"]) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let topics = parseBullets(from: block(matching: ["Topics"]) ?? "")
        let commentary = (block(matching: ["解説"]) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let longForm = commentary.isEmpty ? (quote.isEmpty ? nil : (prose.isEmpty ? nil : prose)) : commentary
        let citation = trimmedOrNil(block(matching: ["引用"]))
        let workBackground = trimmedOrNil(block(matching: ["作品の背景", "作品背景"]))
        let aiCommentary = trimmedOrNil(block(matching: ["AI分析", "AI 分析"]))

        let consumed: Set<String> = ["格言", "本文", "人物の解説", "Topics", "解説", "引用", "作品の背景", "作品背景", "AI分析", "AI 分析"]
        var sections: [CardSection] = []
        for (index, block) in blocks.enumerated() where !consumed.contains(where: { block.0.hasPrefix($0) }) {
            let sectionBody = block.1.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sectionBody.isEmpty else { continue }
            sections.append(CardSection(id: "section-\(index)", heading: block.0, body: sectionBody))
        }
        for (key, value) in meta.extra.sorted(by: { $0.key < $1.key }) {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            sections.append(CardSection(id: "fm-\(sections.count)-\(key)", heading: key, body: trimmed))
        }

        let person = (meta.person ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return .success(Parsed(
            day: meta.day,
            genre: meta.genre,
            person: person.isEmpty ? "不明" : person,
            text: text,
            background: background,
            topics: topics,
            kind: resolvedKind(meta.kind),
            sourceTitle: meta.sourceTitle,
            longForm: longForm,
            sections: sections,
            citation: citation,
            workBackground: workBackground,
            aiCommentary: aiCommentary
        ))
    }
}

private extension MarkdownCardParser {
    static func resolvedKind(_ raw: String?) -> CardKind {
        guard let raw, !raw.isEmpty else { return .proverb }
        return CardKind(rawValue: raw) ?? .other
    }

    static func trimmedOrNil(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }

    static func splitFrontmatter(_ s: String) -> (frontmatter: String?, body: String) {
        guard s.hasPrefix("---\n") else { return (nil, s) }
        let lines = s.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.first == "---" else { return (nil, s) }

        var endIdx: Int? = nil
        for i in 1..<lines.count {
            if lines[i] == "---" {
                endIdx = i
                break
            }
        }
        guard let end = endIdx else { return (nil, s) }

        let front = lines[1..<end].joined(separator: "\n")
        let rest = lines[(end + 1)...].joined(separator: "\n")
        return (String(front), String(rest))
    }

    struct FM: Hashable {
        var day: String? = nil
        var person: String? = nil
        var genre: [String] = []
        var kind: String? = nil
        var sourceTitle: String? = nil
        var extra: [String: String] = [:]
    }

    static func parseFrontmatter(_ fm: String) -> FM {
        var meta = FM()
        let lines = fm.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let reserved = Set(["type", "day", "person", "genre", "kind", "source", "sourceTitle"])

        var currentKey: String? = nil
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }

            if line.hasPrefix("- ") {
                let item = line.dropFirst(2).trimmingCharacters(in: .whitespaces)
                if currentKey == "genre", !item.isEmpty {
                    meta.genre.append(item)
                } else if let currentKey, !reserved.contains(currentKey), !item.isEmpty {
                    let existing = meta.extra[currentKey] ?? ""
                    meta.extra[currentKey] = existing.isEmpty ? item : existing + "\n" + item
                }
                continue
            }

            if let colon = line.firstIndex(of: ":") {
                let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                currentKey = key

                switch key {
                case "day":
                    meta.day = value.isEmpty ? nil : value
                case "person":
                    meta.person = value.isEmpty ? nil : value
                case "genre":
                    if !value.isEmpty {
                        meta.genre = [value]
                    }
                case "kind":
                    meta.kind = value.isEmpty ? nil : value
                case "source", "sourceTitle":
                    meta.sourceTitle = value.isEmpty ? nil : value
                case "type":
                    break
                default:
                    if !value.isEmpty {
                        meta.extra[key] = value
                    }
                }
            }
        }
        return meta
    }

    static func headingBlocks(_ body: String) -> [(heading: String, body: String)] {
        let lines = body.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [(String, [String])] = []
        var currentHeading: String?
        var currentLines: [String] = []

        func flush() {
            if let currentHeading {
                blocks.append((currentHeading, currentLines))
            }
        }

        for line in lines {
            if line.hasPrefix("## ") {
                flush()
                currentHeading = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                currentLines = []
            } else if currentHeading != nil {
                currentLines.append(line)
            }
        }
        flush()
        return blocks.map { (heading: $0.0, body: $0.1.joined(separator: "\n")) }
    }

    static func parseQuote(from s: String) -> String {
        let lines = s.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let quoted = lines
            .compactMap { line -> String? in
                let t = line.trimmingCharacters(in: .whitespaces)
                guard t.hasPrefix(">") else { return nil }
                return t.dropFirst().trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }

        if !quoted.isEmpty {
            return quoted.joined(separator: "\n")
        }
        return s
    }

    static func parseBullets(from s: String) -> [String] {
        s.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .compactMap { line -> String? in
                let t = line.trimmingCharacters(in: .whitespaces)
                guard t.hasPrefix("- ") else { return nil }
                let item = t.dropFirst(2).trimmingCharacters(in: .whitespaces)
                return item.isEmpty ? nil : item
            }
    }
}
