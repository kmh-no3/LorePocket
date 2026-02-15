import SwiftUI
import RealityKit

struct ShowcaseView: View {
    @State private var vm: ShowcaseViewModel
    @State private var scene = ShowcaseScene()
    @State private var lastDragOffset: CGFloat = 0

    init(card: Card? = nil) {
        let cardModel = card.map { CardModel(card: $0) } ?? .sample
        _vm = State(initialValue: ShowcaseViewModel(card: cardModel))
    }

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
                        let delta = value.translation.width - lastDragOffset
                        vm.rotationY += Float(delta) * 0.01
                        lastDragOffset = value.translation.width
                    }
                    .onEnded { _ in
                        lastDragOffset = 0
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
