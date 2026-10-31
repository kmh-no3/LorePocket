import SwiftUI
import UIKit

struct PackCoverView: View {
    let pack: Pack

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(background)

            if let image = PackCoverProvider.coverImage(packId: pack.id) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(pack.meta.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 16)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 18, y: 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(pack.meta.title) の表紙")
    }

    private var background: LinearGradient {
        let hue = Double(abs(pack.id.hashValue % 360)) / 360.0
        let color = Color(hue: hue, saturation: 0.55, brightness: 0.85)
        return LinearGradient(
            colors: [color.opacity(0.95), color.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
