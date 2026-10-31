# LP-16 長文カードデータモデル

## 変更

`Card` に、旧フィールドを残したまま次を足した。

- `kind`: proverb / book / manga / novel / history / person / knowledge / other
- `sourceTitle`: 作品名など
- `longForm`: 1,000字前後の解説
- `sections`: 任意の見出しと本文
- `readingBlocks`: 格言、作品、背景、解説、追加見出しの表示順

既存の `Card(...)` 呼び出しは `kind` が proverb になる。サンプルパックの短文はそのまま。

`cards.json` の読み込みは `CardCoding` に寄せた。`kind` などが無い旧ファイルでも本文は残る。未知の `kind` は `other` にし、カードは捨てない。`id` と `text` が無い要素は従来どおりデコードエラーになる。

## 検証

- `swift test --package-path LorePocketCore`
- 2026-10-31 22:56（Asia/Tokyo）、Swift 6.2.1
- 27 tests, 0 failures（この変更で CardModel 6件を追加）
- Xcode / Simulator は未実行

## 保存時の形

再保存すると `kind` や `sections` などのキーが増える。本文、人物、背景、Topics は残る。進捗ファイルはこの変更では書き換えていない。
