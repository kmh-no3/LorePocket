import SwiftUI

struct PackCarouselView: View {
    let packs: [Pack]
    @Binding var selection: String?
    var canDraw: (Pack) -> Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AccessibilityFocusState private var focusedPackID: String?

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { proxy in
                let cardWidth = CGFloat(CarouselMetrics.cardWidth(containerWidth: proxy.size.width))
                let cardHeight = min(proxy.size.height, cardWidth * 1.22)
                let margin = CGFloat(CarouselMetrics.sideMargin(containerWidth: proxy.size.width, cardWidth: cardWidth))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(packs.enumerated()), id: \.element.id) { index, pack in
                            card(pack, index: index, width: cardWidth, height: cardHeight)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, margin, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $selection)
            }

            if packs.count > 1 {
                pageIndicator
            }
        }
        .onChange(of: focusedPackID) { _, newValue in
            if let newValue {
                selection = newValue
            }
        }
    }

    private func card(_ pack: Pack, index: Int, width: CGFloat, height: CGFloat) -> some View {
        let isSelected = selection == pack.id
        let drawable = canDraw(pack)
        return PackCoverView(pack: pack)
            .frame(width: width, height: height)
            .overlay(alignment: .bottom) {
                Text(drawable ? "今日引ける" : "消化済み")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                    .foregroundStyle(.primary)
                    .padding(.bottom, 14)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
            }
            .scaleEffect(!isSelected && !reduceMotion ? 0.92 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.28), value: isSelected)
            .id(pack.id)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(pack.meta.title)、\(drawable ? "今日引ける" : "今日は消化済み")")
            .accessibilityValue("全\(packs.count)枚中\(index + 1)枚目")
            .accessibilityAddTraits(isSelected ? .isSelected : [])
            .accessibilityFocused($focusedPackID, equals: pack.id)
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(packs) { pack in
                let isSelected = selection == pack.id
                Button {
                    selection = pack.id
                } label: {
                    Capsule()
                        .fill(isSelected ? Color.primary : Color.secondary.opacity(0.35))
                        .frame(width: isSelected && !reduceMotion ? 16 : 6, height: 6)
                }
                .buttonStyle(.plain)
                .accessibilityHidden(true)
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: selection)
    }
}
