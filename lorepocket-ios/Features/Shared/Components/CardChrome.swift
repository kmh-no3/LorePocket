import SwiftUI
import UIKit

// MARK: - UI Components

struct CardView: View {
    let card: Card
    let variant: Variant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VariantBadge(variant: variant)
                Spacer()
                if !card.genre.isEmpty {
                    Text(card.genre.joined(separator: " / "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text("“\(card.text)”")
                .font(.title3.weight(.semibold))
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(card.person)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackground(variant: variant))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(variantTint(variant).opacity(0.25), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            rarityMark(variant: variant)
                .padding(12)
        }
        .padding(.horizontal)
    }
    
    private func variantTint(_ variant: Variant) -> Color {
        switch variant.rarity.lowercased() {
        case "legendary": return .orange
        case "epic": return .purple
        case "rare": return .blue
        default: return .gray
        }
    }
    
    private func cardBackground(variant: Variant) -> some ShapeStyle {
        let baseBackground = Color(uiColor: .systemBackground)
        switch variant.rarity.lowercased() {
        case "legendary":
            return AnyShapeStyle(LinearGradient(
                colors: [.orange.opacity(0.20), .yellow.opacity(0.10), baseBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        case "rare":
            return AnyShapeStyle(LinearGradient(
                colors: [.blue.opacity(0.16), .cyan.opacity(0.08), baseBackground],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
        default:
            return AnyShapeStyle(.background)
        }
    }
    
    @ViewBuilder
    private func rarityMark(variant: Variant) -> some View {
        switch variant.rarity.lowercased() {
        case "legendary":
            Image(systemName: "crown.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.orange)
                .padding(6)
                .background(.ultraThinMaterial, in: Circle())
        case "rare":
            Image(systemName: "seal.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.blue)
                .padding(6)
                .background(.ultraThinMaterial, in: Circle())
        default:
            EmptyView()
        }
    }
}

struct VariantBadge: View {
    let variant: Variant
    
    var body: some View {
        Badge(
            text: variant.name,
            background: tint.opacity(0.2),
            foreground: tint
        )
    }
    
    private var tint: Color {
        switch variant.rarity.lowercased() {
        case "legendary": return .orange
        case "epic": return .purple
        case "rare": return .blue
        default: return .secondary
        }
    }
}

struct Badge: View {
    let text: String
    let background: Color
    let foreground: Color
    
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(background)
            )
    }
}

struct FlowTags: View {
    let tags: [String]
    
    var body: some View {
        // MVP: 簡易表示（折返しは自然に任せる）
        Text(tags.map { "#\($0)" }.joined(separator: "  "))
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
