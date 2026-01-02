# LorePocket 仕様書（Cursor用 / v0.1）

## 1. プロジェクト概要
- **アプリ名**: LorePocket
- **コンセプト**: 毎日1回カードを引き、語録・用語・知識を「カード」として収集するアプリ。
- **狙い**:
  - 学習・教養の習慣化（1日1回の抽選）
  - コレクション要素（コンプ・別柄・レアリティ）
  - **アプリ本体（エンジン）はGitHub公開**、データセット（書籍由来等）は**非公開運用**できる設計

## 2. 要件（MVP）
### 2.1 主要機能
1. **パック選択**: 複数の「カードパック」を追加・選択できる
2. **1日1回ドロー**: パックごとに1日1回カードを引ける（後述ルール）
3. **カード表示**: 引いたカードを表示（格言/人物/背景/Topics）
4. **コレクション**: 所持カード一覧、未所持一覧、進捗（%・枚数）
5. **別柄（Variant）**: 同一カード内容に対し、見た目違いを引ける（レア度付き）
6. **インポート**: ユーザーがデータ（ZIP/JSON）を取り込んで「パック追加」できる（推奨: ZIP）

### 2.2 非機能
- オフライン動作を基本とする
- 反応速度・UIの軽さを優先
- データとロジックを分離（著作権配慮・汎用化）

## 3. 著作権・公開方針
- GitHub公開物に **書籍の本文データは含めない**
- 公開リポジトリには以下のみを含める:
  - アプリ本体（カードエンジン）
  - データ仕様（スキーマ）
  - **自作サンプルパック**（短い例文・架空データ）
- 私的利用データ（例: 「教養としての世界の名言365」由来の格言md/json）は **ローカル/Privateで運用**

## 4. 用語
- **Pack**: カードの集合（例: world-quotes-365, tech-glossary）
- **Card**: 1枚のカード（語録/用語）
- **Draw**: 1日1回の抽選
- **Variant**: 別柄（見た目・エフェクト差）
- **Rarity**: レアリティ（Common/Rare/Epic/Legendary など）
- **Collection**: 所持状況（カード×バリアント）

## 5. データ仕様（公開するスキーマ）

### 5.1 パック構造（ZIP推奨）
```
pack.zip
 ├─ pack.json          # パックメタデータ
 ├─ cards.json         # カード配列（本文）
 ├─ variants.json      # バリアント定義（任意・なければデフォルト）
 └─ assets/            # 画像等（将来拡張・任意）
```

### 5.2 pack.json（例）
```json
{
  "packId": "sample-pack-001",
  "title": "Sample Pack",
  "version": "1.0.0",
  "language": "ja",
  "description": "Sample data for LorePocket.",
  "cardCount": 10,
  "tags": ["sample", "quotes"],
  "legal": { "source": "public", "redistribution": "allowed" }
}
```

### 5.3 cards.json（例）
- **idは必ず packId をprefixとして含める**（衝突回避）
```json
[
  {
    "id": "sample-pack-001-001",
    "genre": ["哲学"],
    "text": "Always carry a notebook.",
    "person": "Sample Author",
    "background": "Short background text...",
    "topics": ["habit", "learning"]
  }
]
```

### 5.4 variants.json（例）
- なければアプリ側のデフォルトを使用
```json
[
  { "variantId": "common", "name": "通常", "rarity": "common", "weight": 80 },
  { "variantId": "foil", "name": "箔押し", "rarity": "rare", "weight": 18 },
  { "variantId": "legend", "name": "レジェンド", "rarity": "legendary", "weight": 2 }
]
```

## 6. アプリ内部モデル（Swift想定）
### 6.1 Model
- `PackMeta`
  - packId, title, version, language, description, tags, legal
- `Card`
  - id, genre:[String], text:String, person:String, background:String, topics:[String]
- `Variant`
  - variantId, name, rarity, weight(Int)
- `OwnedCard`
  - cardId, variantId, obtainedAt(Date)
- `PackProgress`
  - owned:[OwnedCard], lastDrawDate(Date?), drawCount(Int)

### 6.2 Storage（MVP）
- ローカル保存（例: JSONファイル or UserDefaults + JSON）
- パックデータはアプリ内Documentsに保存
- 進捗（所持状況）は `progress.json` で管理

進捗例（イメージ）:
```json
{
  "packs": {
    "sample-pack-001": {
      "lastDrawDate": "2026-01-01",
      "owned": [
        { "cardId": "sample-pack-001-001", "variantId": "common", "obtainedAt": "2026-01-01T00:00:00Z" }
      ]
    }
  }
}
```

## 7. ドロー仕様（重要）
### 7.1 1日1回制限
- **パックごとに** 1日1回引ける（初期仕様）
- 判定はローカル日付（端末のローカル日付でOK / 将来サーバ化も可能）

### 7.2 抽選ロジック（MVP）
1. 今日すでに引いていればブロック（UIで「明日また来てね」）
2. 引ける場合:
   - `Variant` を weight に応じて抽選
   - `Card` を抽選（初期はランダム）
3. 所持状況に応じて **未所持優先** を選べる（推奨）
   - 未所持カードが残っている間は未所持カードから抽選
   - 未所持がなくなったらバリアント収集（同一カードの別柄が出る）

### 7.3 365後も楽しめる仕様
- 全カード所持後は「別柄コンプ」を目標にできる
- 将来: 「コンプ後にレア解放」「季節柄追加」など拡張可能

## 8. 画面設計（MVP）
### 8.1 PackList（パック一覧）
- 追加（インポート）
- パック選択
- 進捗（所持枚数/総数、%）

### 8.2 PackDetail（パック詳細）
- 今日引けるか状態表示
- 「Draw」ボタン
- コレクションへ遷移

### 8.3 DrawResult（結果）
- 引いたカード表示（カードUI）
- バリアント表示（例: バッジ・エフェクト）
- 「閉じる」

### 8.4 Collection（図鑑）
- 所持/未所持フィルタ
- 検索（テキスト/人物）
- カード詳細へ

### 8.5 CardDetail（詳細）
- text / person / background / topics
- 所持バリアント一覧（切替表示）

### 8.6 Settings（設定・MVPは最小）
- 通知（ON/OFF・時刻）は後続フェーズでもOK（MVP外でも可）

## 9. Obsidian連携（将来/運用）
### 9.1 方針
- **アプリは汎用パックインポート**で動く
- Obsidian（md）は私的運用。必要なら:
  - Obsidianフォルダ → `cards.json` へ変換してZIP化 → インポート

### 9.2 Obsidian md推奨テンプレ（参考）
```md
---
type: proverb
day: 001
genre:
  - 政治
person: 人物名
---

## 格言
> 格言本文

## 人物の解説と、格言が生まれた背景
...

## Topics（補足）
- ...
```

## 10. 開発方針（Cursor + Xcode）
- コーディング: Cursor
- 実行/署名/Simulator: Xcode
- リポジトリ案: `lorepocket-ios`

## 11. マイルストーン（おすすめ）
### M0: Hello LorePocket
- SwiftUIテンプレ起動、Git init、Cursorで編集できる

### M1: Card表示
- 仮データでカードを1枚表示できる

### M2: Pack + Draw
- Pack選択、1日1回制限、抽選、結果表示

### M3: Collection
- 所持一覧、未所持一覧、進捗表示

### M4: Import（ZIP）
- pack.zip を取り込んでパック追加

### M5: Variant強化
- レアリティ・別柄の演出、所持バリアント表示

（M6以降: 通知/Widget/Obsidian変換ツール など）

---

## 付録: READMEに書くべき一文（公開用）
- LorePocket is a daily card-drawing app that lets you collect wisdom, lore, and knowledge as cards.
- This repository contains the app engine only. It does not include copyrighted quote datasets.
