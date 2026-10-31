# LP-04 テスト基盤

## 変更

- `DrawEngine` の抽選、`ProgressBook` / `ProgressCoding` の所持と日付、`PackCatalog` / `PackStorage` の保存と Markdown 取り込みを Linux で実行できる Swift Package `LorePocketCore` にした。
- パッケージのソースは `lorepocket-ios/` のエンジンファイルへのシンボリックリンク。編集先はアプリ側だけ。
- `ProgressStore` と `PackLibrary` はこれまでと同じ呼び出しで、規則の本体を上記の型へ委譲する。保存先は従来どおり Documents の `progress.json` と `packs/`。
- `drawCount` が無い古い進捗 JSON でも所持カードを読む。未知のキーは所持を消さない。
- `.github/workflows/core-tests.yml` で `swift test --package-path LorePocketCore` を走らせる。

`ProgressStore` と `PackLibrary` 自体は `Observation` 依存のため、このパッケージには入れていない。テストしているのは両者が呼ぶ規則である。

## 検証

- 実行: Swift 6.2.1（Ubuntu 24.04）、2026-10-31 22:54（Asia/Tokyo）
- コマンド: `swift test --package-path LorePocketCore`
- 結果: 21 tests, 0 failures（DrawEngine 7、PackLibrary 5、PackStats 1、ProgressStore 8）
- Xcode / iOS Simulator では未ビルド。アプリターゲットのコンパイルは未確認。
- GitHub Actions の成否は、この環境からは未観測。

## 維持した挙動

- 未所持カード優先、全カード所持後は未所持バリアントが残るカードを優先、重み 0 は選ばない。
- 同一カード×バリアントは重複追加しない。`drawCount` は増える。
- パックごとのローカル日付で 1 日 1 回。テストの日付境界は Asia/Tokyo。
- サンプルパックは常に先頭。取り込みは `progress.json` を書き換えない。
- 既定バリアントの重みは 80 / 18 / 2 のまま。
