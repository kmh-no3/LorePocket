import Foundation

enum MarkdownCardParser {
    struct Parsed: Hashable {
        let day: String?
        let genre: [String]
        let person: String
        let text: String
        let background: String
        let topics: [String]
    }
    
    /// LorePocket_spec.md のテンプレ（frontmatter + 見出し）を想定してパースする。
    static func parse(markdown: String) -> Parsed? {
        let normalized = markdown
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        let (frontmatter, body) = splitFrontmatter(normalized)
        let meta = parseFrontmatter(frontmatter ?? "")
        
        let quoteBlock = sectionBody(body, headingPrefix: "## 格言")
        let backgroundBlock = sectionBody(body, headingPrefix: "## 人物の解説と、格言が生まれた背景")
        let topicsBlock = sectionBody(body, headingPrefix: "## Topics")
        
        let text = parseQuote(from: quoteBlock).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        
        let person = (meta.person ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let genre = meta.genre
        let day = meta.day
        
        let background = backgroundBlock.trimmingCharacters(in: .whitespacesAndNewlines)
        let topics = parseBullets(from: topicsBlock)
        
        return .init(
            day: day,
            genre: genre,
            person: person.isEmpty ? "不明" : person,
            text: text,
            background: background,
            topics: topics
        )
    }
}

private extension MarkdownCardParser {
    static func splitFrontmatter(_ s: String) -> (frontmatter: String?, body: String) {
        // 先頭に "---\n ... \n---\n" がある場合のみfrontmatterとして扱う
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
    }
    
    static func parseFrontmatter(_ fm: String) -> FM {
        var meta = FM()
        let lines = fm.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        
        var currentKey: String? = nil
        for raw in lines {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            
            if line.hasPrefix("- ") {
                let item = line.dropFirst(2).trimmingCharacters(in: .whitespaces)
                if currentKey == "genre", !item.isEmpty {
                    meta.genre.append(item)
                }
                continue
            }
            
            // key: value
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
                    // genre: の直後が空ならリスト続行、値があれば単一として扱う
                    if !value.isEmpty {
                        meta.genre = [value]
                    }
                default:
                    break
                }
            }
        }
        return meta
    }
    
    static func sectionBody(_ body: String, headingPrefix: String) -> String {
        let lines = body.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var inSection = false
        var buf: [String] = []
        
        for raw in lines {
            let line = raw
            
            if line.hasPrefix("## ") {
                if inSection {
                    break
                } else if line.hasPrefix(headingPrefix) {
                    inSection = true
                    continue
                }
            }
            
            if inSection {
                buf.append(line)
            }
        }
        
        return buf.joined(separator: "\n")
    }
    
    static func parseQuote(from s: String) -> String {
        // > で始まる行を優先して連結。なければテキストをそのまま使う。
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


