import SwiftUI
import Observation

struct DrawResultView: View {
    let pack: Pack
    let result: DrawEngine.DrawResult
    @Bindable var store: ProgressStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.returnHome) private var returnHome
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didAppear = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    CardView(card: result.card, variant: result.variant, emphasize: true, quoteLineLimit: 8)
                        .scaleEffect(reduceMotion || didAppear ? 1 : 0.98)
                        .opacity(reduceMotion || didAppear ? 1 : 0)
                        .animation(reduceMotion ? nil : .spring(duration: 0.35), value: didAppear)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(rarityColor.opacity(0.9), lineWidth: result.variant.rarity.lowercased() == "common" ? 0 : 2)
                                .padding(.horizontal, 16)
                        }
                        .shadow(color: rarityColor.opacity(glowOpacity), radius: glowRadius, y: 8)
                        .accessibilityElement(children: .combine)

                    badges
                        .padding(.horizontal, 20)

                    VStack(alignment: .leading, spacing: 10) {
                        if !result.card.person.isEmpty {
                            labeled("人物", text: result.card.person)
                        }
                        if let source = result.card.sourceTitle, !source.isEmpty {
                            labeled("作品", text: source)
                        }
                        if !backgroundExcerpt.text.isEmpty {
                            labeled("背景", text: backgroundExcerpt.text)
                        }
                        if !result.card.topics.isEmpty {
                            Text("Topics")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            FlowTags(tags: result.card.topics)
                        }
                        if showsDetailHint {
                            Text("全文はカードの詳細で読めます。")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる", action: close)
                        .accessibilityLabel("閉じてホームへ戻る")
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                actions
            }
        }
        .onAppear { didAppear = true }
    }

    private var badges: some View {
        ViewThatFits(in: .horizontal) {
            badgeRow
            VStack(alignment: .leading, spacing: 8) {
                VariantBadge(variant: result.variant)
                if result.wasNewCard {
                    Badge(text: "NEW CARD", background: .green.opacity(0.2), foreground: .green)
                }
                if result.wasNewVariantForCard {
                    Badge(text: "NEW VARIANT", background: .blue.opacity(0.2), foreground: .blue)
                }
            }
        }
    }

    private var badgeRow: some View {
        HStack(spacing: 8) {
            VariantBadge(variant: result.variant)
            if result.wasNewCard {
                Badge(text: "NEW CARD", background: .green.opacity(0.2), foreground: .green)
            }
            if result.wasNewVariantForCard {
                Badge(text: "NEW VARIANT", background: .blue.opacity(0.2), foreground: .blue)
            }
            Spacer(minLength: 0)
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            NavigationLink {
                CardDetailView(cardId: result.card.id, pack: pack, store: store)
            } label: {
                Label("このカードの詳細", systemImage: "text.alignleft")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            NavigationLink {
                CollectionView(pack: pack, store: store)
            } label: {
                Label("図鑑を見る", systemImage: "books.vertical")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private var backgroundExcerpt: (text: String, truncated: Bool) {
        ResultExcerpt.clip(result.card.background, limit: 180)
    }

    private var showsDetailHint: Bool {
        backgroundExcerpt.truncated
            || result.card.text.count > 160
            || !(result.card.longForm ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || result.card.sections.contains { !$0.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private func labeled(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var rarityColor: Color {
        switch result.variant.rarity.lowercased() {
        case "legendary": return .orange
        case "epic": return .purple
        case "rare": return .blue
        default: return .clear
        }
    }

    private var glowOpacity: Double {
        switch result.variant.rarity.lowercased() {
        case "legendary": return 0.45
        case "epic": return 0.3
        case "rare": return 0.22
        default: return 0
        }
    }

    private var glowRadius: CGFloat {
        switch result.variant.rarity.lowercased() {
        case "legendary": return 22
        case "epic": return 14
        case "rare": return 8
        default: return 0
        }
    }

    private func close() {
        dismiss()
        returnHome()
    }
}
