# LorePocket（iOS）

毎日1回カードを引いて「格言・知識・用語」をコレクションする iOSアプリ。  
アプリ本体（エンジン）は公開し、データセットは端末ローカルに取り込んで非公開運用できる設計。

リポジトリ: `https://github.com/kmh-no3/LorePocket.git`

---

## 機能（MVP）
- パック一覧/詳細
- パックごとに1日1回ドロー（未所持カード優先 → 収集後は別柄コンプ）
- 結果表示（レアリティ演出）
- 図鑑（所持/未所持/全部、検索、ソート、進捗）
- Markdownインポート（複数 `.md` からパック生成、ローカル保存）

---

## 技術/構成（要点）
- SwiftUI
- ローカルファースト（進捗: `progress.json`）
- データとロジック分離（著作権データはリポジトリに含めない）
- パック保存形式: `pack.json / cards.json / variants.json`（Documents配下）

---

## 動作要件
- iOS 17+（Observation: `@Observable / @Bindable`）

---

## 著作権・データセット（重要）
このリポジトリは **アプリ本体（エンジン）のみ**。  
書籍由来などの本文データ（Markdown/JSON/ZIP/画像）は **コミット禁止**。

---

## ビルド/実行（開発者向け）
- macOS + Xcode で `lorepocket-ios.xcodeproj` を開き ▶︎ Run（Simulator/実機）

---

## インポート（Markdown → Pack）
パック一覧で **「インポート」** → 複数 `.md` を選択。  
`LorePocket_spec.md` のテンプレ形式（frontmatter + 見出し）をパースし、プライベートパックとして端末内に保存。

### カバー画像（任意）
以下のいずれかを置くと自動表示:
- `Documents/packs/<packId>/assets/cover.png`
- `Documents/packs/<packId>/assets/cover.jpg`
- `Documents/packs/<packId>/assets/cover.jpeg`

---

## ロードマップ
- ZIPインポート（`pack.zip`）
- 画像/演出強化、通知/Widget


