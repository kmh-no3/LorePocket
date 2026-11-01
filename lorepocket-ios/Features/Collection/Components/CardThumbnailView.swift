import SwiftUI

struct CardThumbnailView: View {
    let item: CardListItem
    var onToggleFavorite: (() -> Void)? = nil

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

            VStack(alignment: .leading, spacing: 4) {
                if item.isNew && item.isOwned {
                    CollectionBadge(text: "NEW")
                }
                if let r = item.topRarity, item.isOwned {
                    CollectionBadge(text: r.rawValue.uppercased())
                }
            }
            .padding(10)
            // 右上のお気に入りハート(44pt)とバッジが重ならないよう右側を空け、バッジは縦に積む
            .padding(.trailing, item.isOwned ? 34 : 0)

            if item.isOwned && (item.isFavorite || onToggleFavorite != nil) {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                            .foregroundStyle(item.isFavorite ? Color.pink : Color.secondary)
                            .frame(minWidth: 44, minHeight: 44)
                            .accessibilityHidden(true)
                    }
                    Spacer()
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if item.isOwned, let onToggleFavorite {
                Button(action: onToggleFavorite) {
                    Color.clear
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(item.isFavorite ? "お気に入りを外す" : "お気に入りにする")
            }
        }
    }
}

private struct CollectionBadge: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption2).bold()
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
}
