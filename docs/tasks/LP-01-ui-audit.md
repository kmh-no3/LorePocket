# LP-01 既存UI監査

調査日: 2026-10-31（Asia/Tokyo）
対象: `main` @ `60fe333`（MVP0: パック / ドロー / 図鑑 / Markdownインポート / 3D展示）

## 検証環境

- この作業環境に Xcode / Simulator / `xcodebuild` はない（Linux）。
- 画面遷移は SwiftUI ソースの静的追跡。スクリーンショットは未取得。
- 実行時の見た目、ハプティクス、RealityKit の描画は未検証。

## タブと遷移

実装されているタブは 3 つ（`RootTabView`）。仕様書 8.0 の Home / Library / Collection / Settings のうち **Home はない**。

| 起点 | 遷移 | 実装 |
| --- | --- | --- |
| 起動 | `ContentView` → `RootTabView` | 実装済み |
| パックタブ | `PackListView` | 実装済み |
| パック行 | `PackDetailView`（`navigationDestination(for: Pack.self)`） | 実装済み |
| パック詳細 | Draw → `DrawResultView` を sheet | 実装済み（開封フェーズなし） |
| パック詳細 | `CollectionView` | 実装済み |
| 図鑑タブ | `CollectionsHomeView` → パック選択 → `CollectionView` | 実装済み |
| 図鑑グリッド | `CardDetailView` | 実装済み |
| カード詳細 | `ShowcaseView`（RealityKit） | プロトタイプ |
| 設定タブ | `SettingsView` | 最小 |
| パック一覧 | `.md` の fileImporter | 実装済み |
| 未実装 | Home、開封演出、アルバム、横断検索、エクスポート、通知、Widget | 画面なし |

## 画面ごとの状態

### 実装済み（MVPとして通る）

- **パック一覧** `PackListView`: タイトル、説明、所持数、進捗バー。Markdown複数選択インポート。進捗リセット。
- **パック詳細** `PackDetailView`: 表紙プレースホルダまたは `assets/cover.*`、進捗、別柄進捗、最終ドロー、次回日付、ドロー回数、重みからの確率、1日1回 Draw。
- **抽選** `DrawEngine`: 未所持カード優先 → 全カード所持後は未所持バリアントが残るカード優先 → バリアントは重み抽選。空パックはエラー。
- **1日1回** `ProgressStore.canDrawToday`: パックごとにローカル日付。同一カード×バリアントは重複追加しない。`drawCount` は増える。
- **結果** `DrawResultView`: レア色のカード面、NEW CARD / NEW VARIANT、人物、背景、Topics、閉じる。出現時の短いスケール。
- **図鑑** `CollectionView` + `CollectionViewModel`: 3列 `LazyVGrid`、検索（人物・ジャンル・所持カード本文）、ソート（New / Rarity / Name）、進捗 `n/total (%)`、未所持は暗く `???`、NEW（24h）、最高レア。
- **カード詳細** `CardDetailView`: 本文、人物、ジャンル、背景、Topics、所持バリアントの切替（2種以上で segmented）、コピー、共有、3D展示へのリンク。
- **設定**: 進捗リセット（確認アラート）、MVP表記。
- **3D展示** `ShowcaseView` / `ShowcaseScene`: ドラッグでY回転、ケース3種（clear / smoky / gold）、台座、ポイントライト、白いカード板。
- **データ**: `Documents/packs/<id>/{pack,cards,variants}.json`、`progress.json`、カバー画像。サンプルパックは常に先頭。

### 未完成（入口はあるが仕様に届いていない）

- **図鑑フィルタ**: 所持 / 未所持 / すべて、ジャンル、バリアントの絞り込みがない。検索は Topics・背景・本人の考察を見ない。列数は幅に追従しない。
- **お気に入り**: `CardListItem.isFavorite` は常に `false`。長押しも永続化もない。
- **別柄**: 所持分の切替のみ。未所持バリアントのロック表示はない。チップの横スクロールではない。
- **結果から図鑑へ**: 「図鑑で見る」がない。sheet を閉じると詳細に残るだけ。
- **開封**: 350ms の `ProgressView` のみ。Pack → Open → Reveal、スキップ、Reduce Motion はない。
- **カード詳細の読書**: `List` の短いセクション。1,000〜1,500字を読む組版（格言 / 背景 / 解説 / Topics の階層）ではない。
- **3D**: リセット、ライト操作、台座の切替、ケース切替の安定化（スタイル適用は初回以外差分のみ）が不足。カード面に本文を出していない。
- **インポートエラー**: 「ファイル選択」または「Markdown解析/保存」の定型文。どのファイルのどの見出しが欠けたかは出ない。
- **設定**: テーマ、アニメーション、ハプティクス、通知、データ管理がない。リセットはパック一覧と二重。
- **保存失敗**: `ProgressStore.save` はエラーを捨てる。破損した `progress.json` は空の進捗として読み、次の保存で上書きし得る。

### 未実装

- Home タブ（今日の一枚、引けるパック、進捗の専用画面）
- パックカルーセル（横スワイプ、スナップ、位置、選択アニメーション）
- パック開封演出
- アルバム / ファイリング
- 長文・作品種別の拡張モデル（現行 `Card` は格言フィールド固定）
- 本人の考察、AI分析の分離保存
- ZIPインポート
- カード画像 / サムネイル（カバーのみ）
- 横断検索
- JSON / Markdown エクスポート
- ローカル通知、Widget
- 単体テスト、UIテスト、CI

## 再利用できているもの

重複実装しない。品質改善の土台にする。

- ドロー規則そのもの（`DrawEngine`）は仕様 7.2 に沿っている。1日1回は維持し、課金・ガチャ販売・対戦は足さない。
- `PackStats` の所持・別柄コンプ判定。
- `MarkdownCardParser` の frontmatter + `## 格言` / 背景 / Topics。
- `Rarity`、`CardListItem`、`CollectionViewModel` のソート。
- `PackCoverProvider` のカバー探索とメモリキャッシュ。
- RealityKit の root / 台座 / ケース / ライト構成。

## ファイルの偏り

| ファイル | 行数目安 | 役割 |
| --- | --- | --- |
| `LorePocketViews.swift` | 881 | パック一覧・詳細・結果・図鑑・詳細・私的UI部品が同居 |
| `RootTabView.swift` | 108 | タブと図鑑ホーム、設定 |
| `Features/Collection/` | 分割済み | ViewModel とサムネ |
| `Features/Showcase/` | 分割済み | 3D |
| エンジン | 各100行前後 | Draw / Storage / Parser / Progress。テストターゲットなし |

Xcode は `PBXFileSystemSynchronizedRootGroup` なので、`lorepocket-ios/` 配下の追加 Swift はアプリターゲットに入る。テスト用 Swift はここへ置かない。

## データ安全

- 所持と抽選日は `progress.json`、パック本文は `Documents/packs`。リポジトリのサンプルは架空の短文。
- 私的パック名の定数 `world-quotes-365` とタイトル文字列はインポート先の識別子として既存コードにある。本文データはリポジトリに無い。
- `.gitignore` は `PrivatePacks/`、`**/world-quotes-365/`、`**/*.zip` を除外。

## この監査のあと

1. LP-04: `DrawEngine` / 進捗 / パック読書きの回帰テストを、挙動を変える前に固定する。
2. LP-03: `LorePocketViews.swift` を機能ファイルへ分割する。画面遷移は変えない。
3. LP-02: 既存の角丸・レア色・影をトークン化し、Home 以降の新画面がそれを使う。
4. Wave 1 は欠落している Home・カルーセル・開封・結果導線から足す。図鑑と詳細は既存画面を改善する。
