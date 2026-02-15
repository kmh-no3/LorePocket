# LorePocket — 3D展示ケース（RealityKit）最小プロトタイプ仕様（MVP0）

目的：**SwiftUIアプリ内に、3Dの展示ケース（箱）＋カード（平面）＋ライト**を表示し、  
- 指で回転（ドラッグ）
- ピンチで拡大縮小（任意）
- ボタンでケース/台座の見た目を切替（任意：まずは色や素材差でOK）
を実現する。

> これは「カード対戦なし・鑑賞/収集が主役」のLorePocketの核となる“飾る体験”の最小形。

---

## 1. 前提（ツール）
- Mac + Xcode
- iOS App（Swift / SwiftUI）
- 3D表示：**RealityKit**（`RealityKit` + `ARKit`は不要。ARなしでOK）
- エディタ：Cursor（編集） / Xcode（実行・Simulator）

---

## 2. MVP0で作るもの（超最小）
### 2.1 画面
- `ShowcaseView`（メイン）
  - 上：3D展示（ケース＋カード）
  - 下：UI（カード名、切替ボタン）

### 2.2 3D要素（RealityKit）
- **Case**：透明っぽい箱（まずは半透明Materialで代用）
- **Pedestal**：台座（箱の下の台）
- **Card**：板ポリ（薄い四角）+ テクスチャ（まずは単色 or テキスト）
- **Light**：Directional/Point Light 1つ（影は後で）

### 2.3 操作
- ドラッグ：カード（またはルート）をY軸回転
- ピンチ：ルートをスケール（任意。最初は回転だけでもOK）
- タップ：カードを少し持ち上げる（任意）

---

## 3. プロジェクト構成（提案）
```
LorePocket/
  LorePocketApp.swift
  Features/
    Showcase/
      ShowcaseView.swift
      ShowcaseViewModel.swift
      RealityKit/
        ShowcaseScene.swift
        GestureController.swift
  Shared/
    Models/
      CardModel.swift
    UI/
      LPButtonStyle.swift
```

### 役割
- `ShowcaseView.swift`
  - SwiftUIレイアウト
  - `RealityView`埋め込み
  - ボタン/テキスト表示
- `ShowcaseScene.swift`
  - RealityKitのEntity生成（ケース・台座・カード・ライト）
  - 初期配置
- `GestureController.swift`
  - 回転/スケールなどの入力処理
- `ShowcaseViewModel.swift`
  - 将来：カード差し替え、パック連携、保存状態など

---

## 4. 実装の手順（最短ルート）
### Step 1：SwiftUIに3D表示領域を作る
- `ShowcaseView` を作成
- 画面上部に `RealityView` を配置（iOS 17+）

### Step 2：RealityKitでシーンを生成
- `ShowcaseScene.makeRoot()` で `Entity` ルートを返す
- ルート配下に
  - `caseEntity`（箱）
  - `pedestalEntity`（台）
  - `cardEntity`（板）
  - `lightEntity`
を追加

### Step 3：ドラッグで回転
- SwiftUIの `DragGesture` を受け取り
- `GestureController` で角度を積算
- `rootEntity.transform.rotation` を更新（Y軸）

### Step 4：切替ボタンで素材/色を変える
- `CaseStyle` enum（例：clear / smoky / gold）
- ボタン押下で `ShowcaseViewModel` のstyle更新
- `ShowcaseScene.apply(style:)` でマテリアル差し替え

---

## 5. コード雛形（コピペ用：最小）

> ※ XcodeのiOSバージョンにより `RealityView` が使える/使えないがあります。  
> iOS 17+ をターゲットにするのが最も簡単です。  
> （iOS 16以下なら `ARView` をSwiftUIに埋め込む方式に切り替え可能）

### 5.1 CardModel（仮）
```swift
import Foundation

struct CardModel: Identifiable {
    let id: String
    let title: String
}
```

### 5.2 ShowcaseViewModel（仮）
```swift
import Foundation
import Observation

@Observable
final class ShowcaseViewModel {
    var card: CardModel = .init(id: "sample-001", title: "Sample Card")
    var caseStyle: CaseStyle = .clear
    var rotationY: Float = 0
}

enum CaseStyle: String, CaseIterable, Identifiable {
    case clear, smoky, gold
    var id: String { rawValue }
}
```

### 5.3 ShowcaseView（SwiftUI + RealityView）
```swift
import SwiftUI
import RealityKit

struct ShowcaseView: View {
    @State private var vm = ShowcaseViewModel()
    @State private var scene = ShowcaseScene()

    var body: some View {
        VStack(spacing: 12) {
            // 3D表示
            RealityView { content in
                let root = scene.makeRoot()
                content.add(root)
                scene.apply(style: vm.caseStyle)
            } update: { content in
                scene.setRotationY(vm.rotationY)
                scene.apply(style: vm.caseStyle)
            }
            .frame(height: 420)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // ドラッグ量 -> 回転（調整値は好み）
                        vm.rotationY = Float(value.translation.width) * 0.01
                    }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // UI
            VStack(alignment: .leading, spacing: 8) {
                Text(vm.card.title)
                    .font(.title2).bold()

                HStack {
                    ForEach(CaseStyle.allCases) { style in
                        Button(style.rawValue) {
                            vm.caseStyle = style
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(.horizontal)
            Spacer()
        }
        .padding()
    }
}
```

### 5.4 ShowcaseScene（RealityKitで箱＋台＋カード）
```swift
import Foundation
import RealityKit

@MainActor
final class ShowcaseScene {

    private let root = Entity()
    private let caseEntity = Entity()
    private let pedestalEntity = Entity()
    private let cardEntity = Entity()
    private let lightEntity = Entity()

    private var currentStyle: CaseStyle = .clear

    func makeRoot() -> Entity {
        if root.children.isEmpty {
            setup()
        }
        return root
    }

    func setRotationY(_ y: Float) {
        // ルートをY回転
        root.transform.rotation = simd_quatf(angle: y, axis: [0,1,0])
    }

    func apply(style: CaseStyle) {
        guard style != currentStyle else { return }
        currentStyle = style

        // ケース素材
        let caseMaterial: Material = {
            switch style {
            case .clear:
                var m = SimpleMaterial(color: .white.withAlphaComponent(0.15), isMetallic: false)
                m.roughness = .float(0.1)
                return m
            case .smoky:
                var m = SimpleMaterial(color: .black.withAlphaComponent(0.18), isMetallic: false)
                m.roughness = .float(0.4)
                return m
            case .gold:
                var m = SimpleMaterial(color: .yellow.withAlphaComponent(0.20), isMetallic: true)
                m.roughness = .float(0.2)
                return m
            }
        }()

        if var model = caseEntity.components[ModelComponent.self] as? ModelComponent {
            model.materials = [caseMaterial]
            caseEntity.components.set(model)
        }
    }

    private func setup() {
        // ルート位置
        root.position = [0, 0, 0]

        // 台座
        let pedestalMesh = MeshResource.generateBox(size: [0.55, 0.08, 0.38], cornerRadius: 0.02)
        let pedestalMat = SimpleMaterial(color: .darkGray, isMetallic: false)
        pedestalEntity.components.set(ModelComponent(mesh: pedestalMesh, materials: [pedestalMat]))
        pedestalEntity.position = [0, -0.18, 0]

        // ケース（箱）
        let caseMesh = MeshResource.generateBox(size: [0.60, 0.35, 0.43], cornerRadius: 0.03)
        let caseMat = SimpleMaterial(color: .white.withAlphaComponent(0.15), isMetallic: false)
        caseEntity.components.set(ModelComponent(mesh: caseMesh, materials: [caseMat]))
        caseEntity.position = [0, 0.0, 0]

        // カード（板）
        let cardMesh = MeshResource.generateBox(size: [0.40, 0.56, 0.01], cornerRadius: 0.02)
        let cardMat = SimpleMaterial(color: .white, isMetallic: false)
        cardEntity.components.set(ModelComponent(mesh: cardMesh, materials: [cardMat]))
        cardEntity.position = [0, -0.02, 0.12] // 少し前に出す

        // ライト（PointLight）
        var point = PointLightComponent()
        point.intensity = 2000
        point.attenuationRadius = 2.0
        lightEntity.components.set(point)
        lightEntity.position = [0.4, 0.4, 0.6]

        // 組み立て
        root.addChild(pedestalEntity)
        root.addChild(caseEntity)
        root.addChild(cardEntity)
        root.addChild(lightEntity)
    }
}
```

---

## 6. 最初のデザイン（素材/見た目）
MVP0では画像を作り込まず、次で十分。
- ケース：半透明（alpha 0.1〜0.25）
- 台座：濃いグレー
- カード：白板（後でテクスチャに置換）

> 次段階（MVP1）でカード画像（PNG）を貼り、箔押し/光沢の表現を追加する。

---

## 7. 次の拡張（MVP1〜）
- **カード表面テクスチャ**
  - `TextureResource.load(...)` でカード画像を貼る
- **反転/取り出し演出**
  - タップで回転アニメ（0→180度）
- **ケース種類（3Dモデル差し替え）**
  - USDZ/Reality Composer Proでケースを作る
- **ディスプレイのスロット**
  - “お気に入り枠”に複数カードを並べる
- **保存**
  - お気に入りの展示レイアウトをJSONで保存

---

## 8. 注意（RealityKit/Simulator）
- RealityKitはSimulatorでも動くが、挙動/性能は実機が安定
- まずはSimulatorで動作確認→実機で仕上げがおすすめ

---

## 9. 完了条件（MVP0）
- SwiftUI画面に3Dケースが表示される
- ドラッグでケース全体が回転する
- ボタンでケースの見た目が変わる（最低1種類でもOK）
