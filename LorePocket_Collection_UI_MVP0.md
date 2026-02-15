# LorePocket — コレクション（カード一覧UI）MVP仕様（Pokémon TCG Pocket風）

目的：**取得したカードを“図鑑/コレクション”として一覧表示**し、  
- グリッドで眺める
- 所持/未所持を視覚的に区別する
- フィルタ/ソート/検索で探す
- タップで詳細（カード拡大・別柄表示・3D展示へ遷移）
を実現する。

> 対戦なしのLorePocketでは、この画面の体験がアプリの価値の中心になる。

---

## 1. MVP範囲（最小）
### 必須
- **Pack単位のコレクション画面** `CollectionView(packId:)`
- **グリッド一覧**（サムネ）
- **所持/未所持表示**
  - 所持：通常表示
  - 未所持：暗くする + “???” or ぼかし（著作権的にも安全）
- **タップで詳細** `CardDetailView(cardId:)`
- **進捗表示**（所持枚数/総数 + %）

### 任意（MVP+）
- 検索（人物名/テキスト）
- ソート（取得順/レア順/名前順）
- フィルタ（Genre / Rarity / Favorite）
- NEWバッジ（取得から24hなど）

---

## 2. 画面設計
### 2.1 CollectionView（図鑑）
表示要素：
- 画面上部：Pack名、進捗（例：`120/365 (32%)`）
- ツールバー：検索、ソート、フィルタ
- 本体：グリッド（2〜3列、端末幅で自動調整）

操作：
- **タップ**：カード詳細へ
- **長押し（任意）**：お気に入りON/OFF

### 2.2 CardDetailView（詳細）
表示要素：
- 大きいカード表示（2D）
- タブ/セグメントで
  - 情報（text/person/background/topics）
  - 別柄（variants）
- ボタン：**3D展示で飾る**（Showcaseへ遷移）

---

## 3. データ（一覧表示のための最小モデル）
（既存仕様を前提にMVP用に整理）

### 3.1 Card（内容）
- `id: String`（packId prefix必須）
- `genre: [String]`
- `text: String`
- `person: String`
- `background: String`
- `topics: [String]`

### 3.2 Variant（別柄）
- `variantId: String`（common/foil/legend等）
- `name: String`
- `rarity: String`
- `weight: Int`

### 3.3 OwnedCard（所持）
- `cardId: String`
- `variantId: String`
- `obtainedAt: Date`

### 3.4 PackProgress（進捗）
- `owned: [OwnedCard]`
- `lastDrawDate: Date?`

---

## 4. 一覧表示用ViewModel（重要：高速化と実装簡素化）
### 4.1 CardListItem（表示専用）
- `cardId: String`
- `title: String`（基本は person でもOK）
- `subtitle: String`（genre等）
- `isOwned: Bool`
- `topRarity: Rarity`（所持バリアントの最高レア）
- `isFavorite: Bool`（任意）
- `isNew: Bool`（任意）
- `thumbnailKey: String?`（将来：画像対応用）

> **Card + Progress を毎回UI内で突合しない**  
> → 画面表示前に ViewModelで `CardListItem[]` を作るのがコツ。

---

## 5. UI実装方針（SwiftUI）
### 5.1 グリッド
- `LazyVGrid` を使用（パフォーマンス優先）
- 列数：端末幅で自動（例：iPhoneは2〜3列）
- セルは `CardThumbnailView` に分離

### 5.2 ナビゲーション
- `NavigationStack`
- `NavigationLink` で詳細へ

### 5.3 表示ルール
- 未所持：
  - カード枠は表示するが、中身は暗くする
  - タイトルは `???`
  - レアバッジ非表示
- 所持：
  - 通常表示
  - レアバッジ表示（topRarity）
  - NEWバッジ（任意）

---

## 6. コンポーネント分割（提案）
```
Features/
  Collection/
    CollectionView.swift
    CollectionViewModel.swift
    Components/
      CollectionToolbar.swift
      CollectionProgressHeader.swift
      CardThumbnailView.swift
      RarityBadgeView.swift
    CardDetail/
      CardDetailView.swift
      CardDetailViewModel.swift
```

---

## 7. コード雛形（コピペで動く最小例）
> ※ まずは“ダミーデータで表示”を最短で通す。その後、Pack読み込みとProgress接続。

### 7.1 Rarity（簡易）
```swift
import Foundation

enum Rarity: String, CaseIterable, Comparable {
    case common, rare, epic, legendary

    static func < (lhs: Rarity, rhs: Rarity) -> Bool {
        let order: [Rarity] = [.common, .rare, .epic, .legendary]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}
```

### 7.2 CardListItem
```swift
import Foundation

struct CardListItem: Identifiable, Hashable {
    var id: String { cardId }
    let cardId: String
    let title: String
    let subtitle: String
    let isOwned: Bool
    let topRarity: Rarity?
    let isFavorite: Bool
    let isNew: Bool
}
```

### 7.3 CollectionViewModel（ダミー生成）
```swift
import Foundation
import Observation

@Observable
final class CollectionViewModel {

    var packTitle: String = "Sample Pack"
    var totalCount: Int = 30
    var ownedCount: Int = 12

    var query: String = ""
    var sort: SortOption = .obtainedDesc

    var items: [CardListItem] = []

    enum SortOption: String, CaseIterable, Identifiable {
        case obtainedDesc = "New"
        case rarityDesc = "Rarity"
        case nameAsc = "Name"
        var id: String { rawValue }
    }

    init() {
        // ダミーデータ（所持/未所持混在）
        var tmp: [CardListItem] = []
        for i in 1...totalCount {
            let owned = i <= ownedCount
            let rarity: Rarity? = owned ? (i % 20 == 0 ? .legendary : (i % 7 == 0 ? .epic : (i % 3 == 0 ? .rare : .common))) : nil
            tmp.append(.init(
                cardId: "sample-pack-001-\(String(format: "%03d", i))",
                title: owned ? "Sample Author \(i)" : "???",
                subtitle: owned ? "哲学" : "",
                isOwned: owned,
                topRarity: rarity,
                isFavorite: false,
                isNew: owned && i > ownedCount - 2
            ))
        }
        self.items = tmp
    }

    var filteredItems: [CardListItem] {
        let base = items
        guard !query.isEmpty else { return base }
        return base.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }

    var progressText: String {
        let percent = totalCount == 0 ? 0 : Int(Double(ownedCount) / Double(totalCount) * 100.0)
        return "\(ownedCount)/\(totalCount) (\(percent)%)"
    }
}
```

### 7.4 CollectionView（LazyVGrid）
```swift
import SwiftUI

struct CollectionView: View {
    @State private var vm = CollectionViewModel()

    private var columns: [GridItem] {
        // 端末幅で自動調整（簡易）
        [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                // ヘッダ（進捗）
                HStack {
                    VStack(alignment: .leading) {
                        Text(vm.packTitle).font(.title2).bold()
                        Text(vm.progressText).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // ツールバー（検索）
                HStack {
                    TextField("Search", text: $vm.query)
                        .textFieldStyle(.roundedBorder)

                    Picker("", selection: $vm.sort) {
                        ForEach(CollectionViewModel.SortOption.allCases) { opt in
                            Text(opt.rawValue).tag(opt)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)

                // グリッド
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(vm.filteredItems) { item in
                            NavigationLink(value: item) {
                                CardThumbnailView(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationDestination(for: CardListItem.self) { item in
                CardDetailView(cardId: item.cardId)
            }
        }
    }
}
```

### 7.5 CardThumbnailView（所持/未所持・バッジ）
```swift
import SwiftUI

struct CardThumbnailView: View {
    let item: CardListItem

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.separator, lineWidth: 1)
                )
                .frame(height: 160)

            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(10)
            .frame(height: 160, alignment: .bottomLeading)
            .opacity(item.isOwned ? 1.0 : 0.35) // 未所持は暗く

            // バッジ類
            HStack(spacing: 6) {
                if item.isNew && item.isOwned {
                    Badge(text: "NEW")
                }
                if let r = item.topRarity, item.isOwned {
                    Badge(text: r.rawValue.uppercased())
                }
            }
            .padding(10)
        }
    }
}

private struct Badge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2).bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
}
```

### 7.6 CardDetailView（仮：後で内容表示/3D展示へ）
```swift
import SwiftUI

struct CardDetailView: View {
    let cardId: String

    var body: some View {
        VStack(spacing: 16) {
            Text(cardId).font(.headline)
            RoundedRectangle(cornerRadius: 18)
                .fill(.thinMaterial)
                .frame(height: 420)
                .overlay(Text("Card Preview"))
            Button("Show in 3D Showcase") {
                // TODO: ShowcaseViewへ遷移
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .navigationTitle("Card")
        .navigationBarTitleDisplayMode(.inline)
    }
}
```

---

## 8. データ接続（次の段階：MVP1）
MVP0（ダミー表示）後に以下を追加する：
1. `PackStore`：pack.zipを読み込んで `cards.json` を保持
2. `ProgressStore`：`progress.json` を読み込んで `OwnedCard[]` を保持
3. `CollectionViewModel.buildItems(cards, progress)`：
   - `isOwned` 判定
   - `topRarity` 計算
   - `ownedCount` 集計
4. 画像サムネ（任意）：
   - `thumbnailKey` → ローカル画像 or assets参照

---

## 9. 完了条件（MVP0）
- Packのコレクション画面が表示される（ダミーでOK）
- グリッドでカード一覧が見れる
- 未所持が暗く表示される
- タップで詳細画面へ遷移できる

