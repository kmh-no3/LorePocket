import SwiftUI
import UIKit

struct CardDetailView: View {
    let card: Card
    let pack: Pack
    let owned: [OwnedCard]
    var store: ProgressStore?

    init(cardId: String, pack: Pack, store: ProgressStore) {
        let card = pack.cards.first(where: { $0.id == cardId })
            ?? pack.cards.first!
        let owned = store.progress(for: pack.id).owned.filter { $0.cardId == cardId }
        self.init(card: card, pack: pack, owned: owned, store: store)
    }

    init(card: Card, pack: Pack, owned: [OwnedCard], store: ProgressStore? = nil) {
        self.card = card
        self.pack = pack
        self.owned = owned
        self.store = store
    }

    private var isFavorite: Bool {
        store?.isFavorite(packId: pack.id, cardId: card.id) ?? false
    }

    private func saveReflection() {
        store?.setReflection(packId: pack.id, cardId: card.id, body: reflectionDraft)
    }

    @ViewBuilder
    private func analysisBlock(title: String, body: String?) -> some View {
        if let body, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @State private var selectedVariantId: String? = nil
    @State private var copiedToast = false
    @State private var reflectionDraft = ""
    @State private var reflectionReady = false

    private var ownedVariantIds: Set<String> {
        Set(owned.map(\.variantId))
    }

    private var firstOwnedVariantId: String? {
        pack.variants.first { ownedVariantIds.contains($0.variantId) }?.variantId
    }

    private func variantChip(_ variant: Variant) -> some View {
        let owned = ownedVariantIds.contains(variant.variantId)
        let selected = owned && (selectedVariantId ?? firstOwnedVariantId) == variant.variantId
        return Button {
            selectedVariantId = VariantSelection.choose(
                current: selectedVariantId ?? firstOwnedVariantId,
                requested: variant.variantId,
                ownedIds: ownedVariantIds
            )
        } label: {
            HStack(spacing: 4) {
                if !owned {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                }
                Text(variant.name)
            }
            .font(.subheadline.weight(selected ? .semibold : .regular))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(owned ? Color.primary : Color.secondary)
            .background(
                Capsule().fill(selected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
        .disabled(!owned)
        .accessibilityLabel(owned ? variant.name : "\(variant.name)、未所持")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
    
    var body: some View {
        List {
            Section("カード") {
                let displayVariant: Variant = {
                    if let vid = selectedVariantId,
                       let v = pack.variants.first(where: { $0.variantId == vid }) {
                        return v
                    }
                    if let first = firstOwnedVariantId,
                       let v = pack.variants.first(where: { $0.variantId == first }) {
                        return v
                    }
                    return pack.variants.first ?? Variant(variantId: "common", name: "通常", rarity: "common", weight: 1)
                }()
                
                CardView(card: card, variant: displayVariant)
                    .padding(.horizontal, -16) // Listのインセット調整
                
                HStack {
                    Button {
                        UIPasteboard.general.string = "\(card.text)\n— \(card.person)"
                        copiedToast = true
                    } label: {
                        Label("コピー", systemImage: "doc.on.doc")
                    }

                    Spacer()

                    ShareLink(item: "\(card.text)\n— \(card.person)") {
                        Label("共有", systemImage: "square.and.arrow.up")
                    }
                }

                NavigationLink {
                    ShowcaseView(card: card)
                } label: {
                    Label("3D展示で飾る", systemImage: "cube.transparent")
                }
            }
            
            Section("人物") {
                Text(card.person)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if !card.genre.isEmpty {
                Section("ジャンル") {
                    FlowTags(tags: card.genre)
                        .padding(.vertical, 4)
                }
            }

            ForEach(card.readingBlocks) { block in
                Section(block.title) {
                    Text(block.body)
                        .font(block.id == "text" ? .title3.weight(.semibold) : .body)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
            
            if !card.topics.isEmpty {
                Section("Topics") {
                    FlowTags(tags: card.topics)
                        .padding(.vertical, 4)
                }
            }

            if let analysis = store?.analysis(packId: pack.id, cardId: card.id), !analysis.isEmpty {
                Section {
                    analysisBlock(title: "引用", body: analysis.citation)
                    analysisBlock(title: "作品の背景", body: analysis.workBackground)
                    analysisBlock(title: "AI分析", body: analysis.commentary)
                    Text("外部のAIには接続していません。表示しているのは取り込み済みの文章です。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("取り込み分析")
                }
            }

            if store != nil {
                Section("考察") {
                    TextEditor(text: $reflectionDraft)
                        .frame(minHeight: 160)
                        .accessibilityLabel("自分の考察")
                    Button("考察を保存") {
                        saveReflection()
                    }
                    .disabled(!reflectionReady)
                }
            }
            
            Section("バリアント") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(pack.variants) { variant in
                            variantChip(variant)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .accessibilityLabel("バリアント")

                if ownedVariantIds.isEmpty {
                    Text("未所持")
                        .foregroundStyle(.secondary)
                } else if let variantId = selectedVariantId ?? firstOwnedVariantId,
                          let variant = pack.variants.first(where: { $0.variantId == variantId }),
                          let obtainedAt = owned.first(where: { $0.variantId == variantId })?.obtainedAt {
                    HStack {
                        Text(variant.rarity)
                        Spacer()
                        Text(obtainedAt, style: .date)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if store != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store?.setFavorite(packId: pack.id, cardId: card.id, isFavorite: !isFavorite)
                    } label: {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                    }
                    .accessibilityLabel(isFavorite ? "お気に入りを外す" : "お気に入りにする")
                }
            }
        }
        .alert("コピーしました", isPresented: $copiedToast) {
            Button("OK", role: .cancel) { copiedToast = false }
        }
        .onAppear {
            if selectedVariantId == nil {
                selectedVariantId = firstOwnedVariantId
            }
            if !reflectionReady {
                reflectionDraft = store?.reflection(packId: pack.id, cardId: card.id)?.body ?? ""
                reflectionReady = store != nil
            }
        }
        .onDisappear {
            if reflectionReady {
                saveReflection()
            }
        }
    }
}
