# LP-03 画面ファイルの分割

## 方針

`LorePocketViews.swift` と `RootTabView.swift` にまとまっていた SwiftUI の画面を、機能ごとのファイルへ移した。移したのは宣言そのもので、画面の挙動は意図的に変えていない。文言、レイアウト、遷移、ドロー規則もそのままである。

シンボル名の変更、整形、エンジン側の編集はしていない。対象外としたのは `DrawEngine`、`ProgressStore`、`PackStorage`、`PackLibrary`、モデル、パーサー、ショーケースである。`CollectionViewModel` も既存のまま触っていない。

Xcode プロジェクトは `lorepocket-ios/` を synchronized root group として取り込んでいる。新しい Swift ファイルはそこに置いたので、`project.pbxproj` は編集していない。

`PackDetailView` は `Image(uiImage:)` を使う。ターゲットの `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` では、分割後のファイルから UIKit の初期化子を呼ぶために `import UIKit` が要る。元の巨大ファイルはファイル先頭で UIKit を import していた。

## 移動したもの

削除したファイル:

- `lorepocket-ios/LorePocketViews.swift`

新しく置いたファイル:

- `lorepocket-ios/Features/Packs/PackListView.swift`
  - `PackListView`
  - `private extension PackListView`
  - `PackRow`
  - `private struct PackProgressPill`
- `lorepocket-ios/Features/Packs/PackDetailView.swift`
  - `PackDetailView`
  - `private extension PackDetailView`
  - `private struct PackThumbView`
  - `private struct PackCoverHeroView`
- `lorepocket-ios/Features/Draw/DrawResultView.swift`
  - `DrawResultView`
- `lorepocket-ios/Features/Collection/CollectionView.swift`
  - `CollectionView`
- `lorepocket-ios/Features/Collection/CardDetailView.swift`
  - `CardDetailView`
- `lorepocket-ios/Features/Shared/Components/CardChrome.swift`
  - `CardView`
  - `VariantBadge`
  - `Badge`
  - `FlowTags`
- `lorepocket-ios/Features/Collection/CollectionsHomeView.swift`
  - `CollectionsHomeView`（`RootTabView.swift` から移動）
- `lorepocket-ios/Features/Settings/SettingsView.swift`
  - `SettingsView`（`RootTabView.swift` から移動）

残したファイル:

- `lorepocket-ios/RootTabView.swift` は `RootTabView` だけにした。

## アクセスと import

別ファイルから使えるように、`CardView`、`VariantBadge`、`Badge`、`FlowTags` の型宣言から `private` だけを外した。型の中にある `private` のメンバーはそのままである。

それ以外の `private struct` と `private extension` は private のまま、それを使う型と同じファイルに置いた。

各ファイルの `import` は、そのファイルが使うものだけにした。使っているモジュールは `SwiftUI`、`Observation`、`UniformTypeIdentifiers`、`UIKit` である。`CardDetailView` は `UIPasteboard` のため `UIKit` を import する。`PackListView` は `UTType` のため `UniformTypeIdentifiers` を import する。`CardChrome` は `Color(uiColor:)` のため `UIKit` を import する。

## ビルド

この環境には Xcode が入っていない。`xcodebuild` も Simulator も実行していない。

分割のあと、作業ツリーを検索し、次の名前の型宣言がそれぞれ 1 回だけであることと、`LorePocketViews.swift` が無いことを確認した。

- `PackListView`
- `PackDetailView`
- `DrawResultView`
- `CollectionView`
- `CardDetailView`
- `CardView`
- `CollectionsHomeView`
- `SettingsView`
- `RootTabView`

`PackListView` と `PackDetailView` には、同じ型に対する `private extension` がそれぞれ 1 つある。これは移す前から同じファイル内にあったもので、型の宣言が増えたわけではない。
