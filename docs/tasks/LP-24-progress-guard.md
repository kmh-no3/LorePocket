# LP-24 進捗ファイルの保護

## 変更

壊れた `progress.json` を読んだとき、アプリは空の進捗をメモリに出すが、**元ファイルは上書きしない**。同じ内容を `progress.corrupt-<unix時間>.json` にコピーする。明示的なリセットのあとだけ、空の進捗を書き戻す。コピーは残る。

欠けた `drawCount` の旧ファイルは、これまでどおり所持カードを読んで書き込みを許可する。ファイルが無い初回起動も、これまでどおり新規作成できる。

`ProgressStore` はこの `ProgressSession` を使う。保存そのものは従来の atomic write。

## 検証

- `swift test --package-path LorePocketCore`
- 2026-10-31 22:57（Asia/Tokyo）、Swift 6.2.1
- 30 tests, 0 failures（ProgressFileGuard 3件を追加）
- Xcode / Simulator は未実行
- 破損時の警告文は `loadWarning` に入る。設定画面への表示は未接続。

## 残る限界

リセットはユーザー確認のあと、元ファイルを空の正当な JSON で置き換える。復旧用コピーは消さない。コピーに失敗した場合も元ファイルは書き換えないが、復旧用パスは nil になる。
