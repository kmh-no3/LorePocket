# LP-10 カード詳細の読書

## 変更

カード詳細の本文と背景の短い欄を、`Card.readingBlocks` の縦の節に変えた。格言、作品、背景、解説、追加見出しがこの順で出る。長い文章は折り返し、行間を取り、選択できる。行数では切らない。

人物、ジャンル、Topics、カード面、コピー、共有、3D展示は残した。

考察の入力と「取り込み分析」は別の節のまま。分析の文章を考察欄へは入れない。

## テスト

`readingBlocks` の並びは既存の `CardModelTests` が持っている。`swift test --package-path LorePocketCore` を再実行する。

Xcode / Simulator は未実行。長い本文の組版は未検証。

## 前提ブランチ

`cursor/lp-09-collection-5fce`
