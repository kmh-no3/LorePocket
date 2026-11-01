import SwiftUI
import RealityKit

struct ShowcaseView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var vm: ShowcaseViewModel
    @State private var scene = ShowcaseScene()
    @State private var lastDragOffset: CGFloat = 0
    @State private var resetAnimation: Task<Void, Never>?
    @State private var resetGeneration = 0

    init(card: Card? = nil) {
        let cardModel = card.map { CardModel(card: $0) } ?? .sample
        _vm = State(initialValue: ShowcaseViewModel(card: cardModel))
    }

    var body: some View {
        let rotationY = vm.rotationY
        let presentation = vm.presentation

        VStack(spacing: 12) {
            showcaseCanvas(rotationY: rotationY, presentation: presentation)
            .frame(height: 420)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        cancelResetAnimation()
                        let delta = value.translation.width - lastDragOffset
                        vm.rotationY += Float(delta) * 0.01
                        lastDragOffset = value.translation.width
                    }
                    .onEnded { _ in
                        lastDragOffset = 0
                    }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .accessibilityLabel("回転")
            .accessibilityHint("左右にドラッグして展示を回転します")
            .accessibilityAddTraits(.allowsDirectInteraction)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(vm.card.title)
                        .font(.title2).bold()

                    ShowcaseOptionButtons(
                        caption: "ケース",
                        accessibilityLabel: "ケース",
                        options: CaseStyle.allCases,
                        selection: vm.caseStyle,
                        title: { $0.title },
                        select: { vm.caseStyle = $0 }
                    )

                    ShowcaseOptionButtons(
                        caption: "ライト",
                        accessibilityLabel: "ライト",
                        options: LightPreset.allCases,
                        selection: vm.lightPreset,
                        title: { $0.title },
                        select: { vm.lightPreset = $0 }
                    )

                    ShowcaseOptionButtons(
                        caption: "台座",
                        accessibilityLabel: "台座",
                        options: PedestalStyle.allCases,
                        selection: vm.pedestalStyle,
                        title: { $0.title },
                        select: { vm.pedestalStyle = $0 }
                    )

                    Button("リセット", action: resetShowcase)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .accessibilityLabel("リセット")
                        .accessibilityHint("回転、ケース、ライト、台座を初期状態に戻します")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .onDisappear {
            cancelResetAnimation()
        }
    }

    /// iOS 18 以降は RealityView、iOS 17 は ARView(.nonAR) で同じ ShowcaseScene を描く。
    @ViewBuilder
    private func showcaseCanvas(rotationY: Float, presentation: ShowcasePresentation) -> some View {
        if #available(iOS 18.0, *) {
            RealityView { content in
                let root = scene.makeRoot()
                content.add(root)
                scene.setRotationY(rotationY)
                scene.apply(presentation)
            } update: { content in
                scene.setRotationY(rotationY)
                scene.apply(presentation)
            }
        } else {
            LegacyShowcaseARView(scene: scene, rotationY: rotationY, presentation: presentation)
        }
    }

    private func resetShowcase() {
        cancelResetAnimation()

        if reduceMotion {
            vm.reset()
            return
        }

        let start = wrappedAngle(vm.rotationY)
        vm.reset(rotationY: start)
        guard abs(start) > 0.000_1 else { return }

        let generation = resetGeneration
        resetAnimation = Task { @MainActor in
            let steps = 12
            for step in 1...steps {
                if Task.isCancelled || generation != resetGeneration { return }
                let t = Float(step) / Float(steps)
                let eased = t * t * (3 - 2 * t)
                vm.rotationY = start * (1 - eased)
                if step == steps {
                    if generation == resetGeneration {
                        resetAnimation = nil
                    }
                    return
                }
                do {
                    try await Task.sleep(for: .milliseconds(30))
                } catch {
                    return
                }
            }
        }
    }

    private func cancelResetAnimation() {
        guard resetAnimation != nil else { return }
        resetGeneration += 1
        resetAnimation?.cancel()
        resetAnimation = nil
    }

    /// 蓄積したドラッグ角を ±π に畳み、リセットが何周も回らないようにする。
    private func wrappedAngle(_ angle: Float) -> Float {
        let twoPi = Float.pi * 2
        var wrapped = angle.truncatingRemainder(dividingBy: twoPi)
        if wrapped > .pi {
            wrapped -= twoPi
        } else if wrapped < -.pi {
            wrapped += twoPi
        }
        return wrapped
    }
}

private struct ShowcaseOptionButtons<Option: Identifiable & Equatable>: View {
    let caption: String
    let accessibilityLabel: String
    let options: [Option]
    let selection: Option
    let title: (Option) -> String
    let select: (Option) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options) { option in
                        optionButton(option)
                    }
                }
                .controlSize(.small)
                .padding(.vertical, 2)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private func optionButton(_ option: Option) -> some View {
        let isSelected = option == selection
        if isSelected {
            Button(title(option)) { select(option) }
                .buttonStyle(.borderedProminent)
                .accessibilityAddTraits(.isSelected)
        } else {
            Button(title(option)) { select(option) }
                .buttonStyle(.bordered)
        }
    }
}

/// iOS 17 向けフォールバック。RealityView(iOS 18+) の代わりに非AR の ARView を使う。
private struct LegacyShowcaseARView: UIViewRepresentable {
    let scene: ShowcaseScene
    let rotationY: Float
    let presentation: ShowcasePresentation

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        view.environment.background = .color(.clear)
        let anchor = AnchorEntity(world: .zero)
        anchor.addChild(scene.makeRoot())
        let camera = PerspectiveCamera()
        camera.look(at: [0, -0.02, 0], from: [0, 0.15, 1.1], relativeTo: nil)
        anchor.addChild(camera)
        view.scene.addAnchor(anchor)
        scene.setRotationY(rotationY)
        scene.apply(presentation)
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        scene.setRotationY(rotationY)
        scene.apply(presentation)
    }
}
