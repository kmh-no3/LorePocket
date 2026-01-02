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

### 2.3 UI/UX 方針（ポケポケ参考）
- **参考元**: ポケポケ（Pokemon Trading Card Game Pocket）の **UI体験**（導線・密度・演出の気持ちよさ）を参考にする
  - ただし **アート/ロゴ/効果音/固有表現/アイコン類は流用しない**（自作・フリー素材・抽象表現のみ）
- **狙い**:
  - 「パックを選ぶ → 引く → 開ける → 図鑑で眺める」のループを短く快適にする
  - 1日1回制限でも「今日の一枚」の体験価値を上げる（演出・余韻・収集の手触り）
- **デザイン原則**:
  - **ホームは迷わせない**（今日引けるパックが一番目立つ）
  - **カードを主役**（UIは余白多め、情報は段階的に表示）
  - **操作は片手**（下部に主要操作、スワイプ主体）
  - **演出は短く、スキップ可能**（“気持ちいい”が“待たされる”にならない）
  - **状態が一目で分かる**（引ける/引けない、進捗、未所持残数）

## 3. 著作権・公開方針
- GitHub公開物に **書籍の本文データは含めない**
- 公開リポジトリには以下のみを含める:
  - アプリ本体（カードエンジン）
  - データ仕様（スキーマ）
  - **自作サンプルパック**（短い例文・架空データ）
- 私的利用データ（例: 「教養としての世界の名言365」由来の格言md/json）は **ローカル/Privateで運用**
- **UI参考に関する注意**:
  - ポケポケの **画面キャプチャや画像アセットの同梱は禁止**
  - 文言・アイコン・配置の **完全なトレースは避ける**（体験として参考に留める）

## 4. 用語
- **Pack**: カードの集合（例: world-quotes-365, tech-glossary）
- **Card**: 1枚のカード（語録/用語）
- **Draw**: 1日1回の抽選
- **Variant**: 別柄（見た目・エフェクト差）
- **Rarity**: レアリティ（Common/Rare/Epic/Legendary など）
- **Collection**: 所持状況（カード×バリアント）
- **Pack Opening**: パック開封演出（封→開→カード露出→確定表示）

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
### 8.0 ナビゲーション（ポケポケ参考の導線）
- **タブ（下部）**: Home / Library / Collection / Settings
  - Home: 今日のドロー中心（最短導線）
  - Library: パック管理（追加・並び替え・詳細）
  - Collection: 図鑑（検索/フィルタ/詳細）
  - Settings: 端末設定・表示設定

### 8.1 Home（今日のドロー）
- **上部**: アプリ名 + シンプルな状態表示（例: 「今日のドロー」）
- **中央**: 「今日引けるパック」カルーセル
  - パック表紙（Cover）を大きめに、左右スワイプで切替（ポケポケの“パック選択”の気持ちよさを参考）
  - 各パックに進捗（%・所持/総数・未所持残数）を小さく表示
- **主要CTA（下部固定）**:
  - 引ける場合: **Draw**（強調ボタン）
  - 引けない場合: **明日また来てね** + 次回可能時刻（任意）
- **補助導線**:
  - 「図鑑」へ（選択中パックに絞って開く）
  - 「パック管理」へ（Libraryタブへ誘導）

### 8.2 Library（パック一覧/管理）
- **一覧**:
  - パックをカード状に表示（表紙 + タイトル + 進捗）
  - 並び替え（ドラッグ or 編集モード）は後回しでもOK
- **追加（インポート）**:
  - 「+」または「インポート」ボタンから `pack.zip` を取り込み
  - 取り込み後は自動で一覧に追加し、必要なら詳細へ誘導
- **パック選択**:
  - タップで `PackDetail` へ
  - 長押し（任意）でメニュー（削除/非表示/情報）

### 8.3 PackDetail（パック詳細）
- **パックヘッダ**: 表紙 + タイトル + タグ + 説明（折りたたみ可）
- **状態**: 今日引ける/引けない、最終ドロー日、ドロー回数
- **進捗**: 所持/総数、未所持残数、別柄の所持数（任意）
- **CTA**: Draw（Homeと同じ挙動）
- **サブ**: コレクションへ（このパックでフィルタして遷移）

### 8.4 DrawResult（結果）
#### 8.4.1 開封演出（ポケポケ参考）
- **フェーズ1: Pack**  
  - パック（表紙）を中央に表示、軽い揺れ/光沢、タップで開始
- **フェーズ2: Open**  
  - 引き裂き/開封の抽象アニメ（実物を模した露骨な表現は避ける）
  - **スキップ**（右上）を必ず用意
- **フェーズ3: Reveal**  
  - カードがせり出し、タップ/スワイプで表面表示（“めくる”気持ちよさを参考）
  - レア/バリアントに応じて、**控えめなグロー/パーティクル**（過剰にしない）
  - 可能なら **軽いハプティクス**（iOSの範囲で）
#### 8.4.2 結果画面（確定表示）
- 引いたカード（本文・人物・Topicsの抜粋）
- バリアント表示（バッジ + レアリティ色）
- アクション:
  - 「図鑑で見る」（該当カード詳細へ）
  - 「閉じる」（Homeへ）

### 8.5 Collection（図鑑）
#### 8.5.1 一覧（ポケポケ参考の“並べて眺める”）
- **グリッド**（2〜3列、端末幅に応じて可変）
- **サムネ**:
  - 所持: 表紙（カード面）を表示
  - 未所持: シルエット/ぼかし（“影”表現）+ No.（任意）
- **フィルタ**:
  - 所持/未所持/すべて
  - ジャンル（複数選択）
  - バリアント（common/foil等）
- **検索**:
  - text / person / topics を対象（ローカル全文検索はMVPでは簡易でOK）
- **ソート**:
  - 追加順（獲得日時）/ A-Z / 未所持優先（任意）

### 8.6 CardDetail（詳細）
#### 8.6.1 表示（カードが主役）
- **カード面**（上）: バリアントごとの見た目（背景色/枠/光沢で差分）
- **本文**: text
- **補足**: person / background / topics（情報量が多い場合は折りたたみ）
#### 8.6.2 バリアント切替
- 所持バリアントを **横スクロールのチップ**で切替
- 未所持バリアントはロック表示（将来: “あと何回で出る？”等の案内も可）

### 8.7 Settings（設定・MVPは最小）
- 通知（ON/OFF・時刻）は後続フェーズでもOK（MVP外でも可）
- **演出設定（推奨）**:
  - 開封演出: ON/OFF
  - ハプティクス: ON/OFF
  - 省電力時の簡略化（任意）

### 8.8 UIコンポーネント（実装分割の目安）
- `PackCoverView`: パック表紙表示（影・角丸・軽い光沢）
- `PackCarouselView`: Homeのカルーセル（スナップ・インジケータ）
- `DrawCTAButton`: 状態に応じた主要ボタン
- `PackOpeningView`: 開封演出（スキップ・フェーズ管理）
- `CardFaceView`: カード面（本文・装飾）
- `RarityBadgeView`: レアリティ/バリアント表示
- `CollectionGridView`: 図鑑グリッド（未所持の表現含む）
- `FilterBarView`: フィルタ/検索 UI

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

### M6: UI磨き（ポケポケ参考）
- Homeカルーセルの完成度（スナップ、触り心地）
- 開封演出（スキップ、短時間、端末性能に応じた簡略化）
- 図鑑グリッド（未所持表現、フィルタ/検索、詳細遷移）

（M7以降: 通知/Widget/Obsidian変換ツール など）

---

## 付録: READMEに書くべき一文（公開用）
- LorePocket is a daily card-drawing app that lets you collect wisdom, lore, and knowledge as cards.
- This repository contains the app engine only. It does not include copyrighted quote datasets.
