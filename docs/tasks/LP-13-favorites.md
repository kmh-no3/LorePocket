# LP-13 お気に入り

## 変更

`isFavorite` の固定値をやめ、パックごとの `favoriteCardIds` を `progress.json` に保存する。

- 同じカード ID は一度だけ入る。外しても所持カードとドロー回数は残る。
- 旧進捗 JSON にこのキーが無くても所持カードは読める。
- 図鑑サムネのハートと、カード詳細のハートで切り替える。未所持のサムネにはハートを出さない。
- ハートの当たり判定は 44pt。NavigationLink の中にあるため、タップが詳細遷移と同時に起きる可能性は Simulator 未確認。

## 検証

- `swift test --package-path LorePocketCore` に、お気に入りが所持を消さないことと、旧 JSON の favorites が空であることを追加。
- Xcode / Simulator では未実行。ハートの見た目と、一覧に戻ったときの再描画は未確認。
