import SwiftUI
import UIKit

struct CardDetailView: View {
    let card: Card
    let pack: Pack
    let owned: [OwnedCard]

    init(cardId: String, pack: Pack, store: ProgressStore) {
        let card = pack.cards.first(where: { $0.id == cardId })
            ?? pack.cards.first!
        let owned = store.progress(for: pack.id).owned.filter { $0.cardId == cardId }
        self.init(card: card, pack: pack, owned: owned)
    }

    init(card: Card, pack: Pack, owned: [OwnedCard]) {
        self.card = card
        self.pack = pack
        self.owned = owned
    }

    @State private var selectedVariantId: String? = nil
    @State private var copiedToast = false

    private var ownedVariantIds: [String] {
        Array(Set(owned.map(\.variantId))).sorted()
    }
    
    var body: some View {
        List {
            Section("カード") {
                let displayVariant: Variant = {
                    if let vid = selectedVariantId,
                       let v = pack.variants.first(where: { $0.variantId == vid }) {
                        return v
                    }
                    if let first = ownedVariantIds.first,
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
            
            Section("本文") {
                Text(card.text)
            }
            
            Section("人物") {
                Text(card.person)
            }
            
            if !card.genre.isEmpty {
                Section("ジャンル") {
                    FlowTags(tags: card.genre)
                        .padding(.vertical, 4)
                }
            }
            
            if !card.background.isEmpty {
                Section("背景") {
                    Text(card.background)
                }
            }
            
            if !card.topics.isEmpty {
                Section("Topics") {
                    FlowTags(tags: card.topics)
                        .padding(.vertical, 4)
                }
            }
            
            Section("所持バリアント") {
                if ownedVariantIds.isEmpty {
                    Text("未所持")
                        .foregroundStyle(.secondary)
                } else {
                    if ownedVariantIds.count >= 2 {
                        Picker("表示中", selection: Binding(
                            get: { selectedVariantId ?? ownedVariantIds.first! },
                            set: { selectedVariantId = $0 }
                        )) {
                            ForEach(ownedVariantIds, id: \.self) { vid in
                                Text(vid).tag(vid)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    ForEach(ownedVariantIds, id: \.self) { variantId in
                        if let v = pack.variants.first(where: { $0.variantId == variantId }) {
                            let obtainedAt = owned.first(where: { $0.variantId == variantId })?.obtainedAt
                            HStack {
                                VariantBadge(variant: v)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(v.rarity)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if let date = obtainedAt {
                                        Text(date, style: .date)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } else {
                            Text(variantId)
                        }
                    }
                }
            }
        }
        .navigationTitle("詳細")
        .navigationBarTitleDisplayMode(.inline)
        .alert("コピーしました", isPresented: $copiedToast) {
            Button("OK", role: .cancel) { copiedToast = false }
        }
        .onAppear {
            if selectedVariantId == nil {
                selectedVariantId = ownedVariantIds.first
            }
        }
    }
}
