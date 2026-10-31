import Foundation

/// 結果画面に出す短い抜粋。全文はカード詳細へ渡す。
enum ResultExcerpt {
    static func clip(_ text: String, limit: Int = 180) -> (text: String, truncated: Bool) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard limit > 0, trimmed.count > limit else { return (trimmed, false) }
        let end = trimmed.index(trimmed.startIndex, offsetBy: limit)
        let head = trimmed[..<end].trimmingCharacters(in: .whitespacesAndNewlines)
        return (head + "…", true)
    }
}
