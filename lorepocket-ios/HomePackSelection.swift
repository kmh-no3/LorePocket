import Foundation

/// ホームが最初に出すパック。今日引けるものがあればその先頭、無ければ一覧の先頭。
enum HomePackSelection {
    static func featured(in packs: [Pack], canDraw: (String) -> Bool) -> Pack? {
        packs.first(where: { canDraw($0.id) }) ?? packs.first
    }
}
