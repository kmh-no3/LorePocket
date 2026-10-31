import Foundation

/// 未所持のバリアントは表示中の選択を変えない。
enum VariantSelection {
    static func choose(current: String?, requested: String, ownedIds: Set<String>) -> String? {
        guard ownedIds.contains(requested) else { return current }
        return requested
    }
}
