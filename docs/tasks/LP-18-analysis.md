# LP-18 AI分析の分離保存

## 変更

引用、作品の背景、AI分析文を `CardAnalysis` として `progress.json` の `analyses` に保存する。本人の考察 `reflections` とは別である。

空の分析はキーを消す。そのとき考察と所持カードは残る。旧ファイルに `analyses` が無くても所持は読める。

カード詳細は、分析があるときだけ「取り込み分析」を読む専用で出す。アプリから外部AIへは接続しない。

## 検証

モデルの分離と JSON 往復は `swift test --package-path LorePocketCore` に追加した。Swift 6.2.1。Xcode / Simulator は未実行。
