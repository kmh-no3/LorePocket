# LP-05 ホーム

## 変更

- `RootTabView` の先頭にホームタブを足し、起動時の選択にした。パック、図鑑、設定はそのまま。
- `HomeView` は今日引けるパックを大きく出す。無ければ一覧の先頭。表紙、今日引けるか、所持枚数、収集率、下部の「引く」、そのパックの図鑑へのリンク。
- パックが0件のときは空状態にし、パックタブへ移る。
- 抽選は `DrawSession` と既存の `DrawEngine` / `ProgressStore.recordDraw`。ホーム用の別抽選は作っていない。開封演出はまだ無く、引いたあとは既存の結果シートを出す。
- 主役の選び方は `HomePackSelection` に切り出し、テストした。

## テスト

`swift test --package-path LorePocketCore`：45件成功（2026-10-31、Swift 6.2.1）。ホームの選び方3件を追加し、既存42件も通った。

Xcode / Simulator は未実行。レイアウト、片手での押しやすさ、ライトとダークの見た目は未検証。

## 前提ブランチ

`cursor/integrate-lp-chain-5fce`
