import SwiftUI

struct CardThumbnailView: View {
    let item: CardListItem

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.separator, lineWidth: 1)
                )
                .frame(height: 160)

            VStack(alignment: .leading, spacing: 6) {
                Spacer()
                Text(item.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(10)
            .frame(height: 160, alignment: .bottomLeading)
            .opacity(item.isOwned ? 1.0 : 0.35)

            HStack(spacing: 6) {
                if item.isNew && item.isOwned {
                    CollectionBadge(text: "NEW")
                }
                if let r = item.topRarity, item.isOwned {
                    CollectionBadge(text: r.rawValue.uppercased())
                }
            }
            .padding(10)
        }
    }
}

private struct CollectionBadge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2).bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
}
