# 統合ブランチ（PR #1〜#10）

検証用。`main` へはマージしない。

土台は #9 の先端 `cursor/lp-19-markdown-import-5cf7`（#2 → #3 → #4 → #5 → #7 → #8 → #9）。その上に #6 と #10 をマージし、#1 の監査ドキュメントを置いた。既存ブランチは上書きしていない。

## 取り込んだもの

- #2〜#9: ドローと進捗のテスト、長文カード、壊れた進捗の保護、お気に入り、本人の考察、取り込み分析、Markdown の失敗理由。
- #6: `LorePocketViews.swift` の削除と、パック・ドロー結果・図鑑・詳細・設定・共通カード部品への分割。`PackDetailView` の `import UIKit` を含む。
- #10: 展示ケースのリセット、ライト、台座。
- #1: `docs/tasks/LP-01-ui-audit.md`。

## 衝突の解消

#6 は `LorePocketViews.swift` を削除し、#9 までのチェーンは同じファイルにお気に入り、考察、分析表示、インポート報告を足していた。

削除を採用し、チェーン側の画面差分だけを分割先へ移した。

- `Features/Packs/PackListView.swift`: 取り込み報告、失敗したファイル名、`setAnalysis`。
- `Features/Collection/CollectionView.swift`: サムネのハートで `toggleFavorite`。`CollectionViewModel` と `CardThumbnailView` はチェーン側の実装のまま。
- `Features/Collection/CardDetailView.swift`: お気に入り、考察の保存、取り込み分析の読み取り専用表示。考察と AI 分析は別セクション。

#10 の展示ファイルはチェーンが触っていなかったので、そのままマージできた。

## 検証

`swift test --package-path LorePocketCore`：42件成功（2026-10-31、Swift 6.2.1、Ubuntu 24.04）。既存35件に、`DrawSession` の7件を加えた。

## 抽選の入口

同じブランチに `DrawSession` を足した。画面からはまだ呼んでいない。封のままでは引かず、タップかスキップの最初の1回だけ `DrawEngine.draw` を呼ぶ。`shouldPersist` もその1回だけ真になる。引けない日は抽選しない。保存そのものは既存の `ProgressBook.recordDraw` / `ProgressStore.recordDraw` に任せる。

Xcode / Simulator / `xcodebuild` はこの環境に無い。アプリのビルド、画面の見た目、RealityKit の描画は未検証。ビルド成功とは扱わない。

## 以後の UI

LP-05 以降は、この統合ブランチ `cursor/integrate-lp-chain-5fce` から切る。既存の PR ブランチには戻さない。
