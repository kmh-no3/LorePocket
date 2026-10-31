import SwiftUI
import Observation

struct DrawResultView: View {
    let pack: Pack
    let result: DrawEngine.DrawResult
    @Bindable var store: ProgressStore
    
    @Environment(\.dismiss) private var dismiss
    @State private var didAppear = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    CardView(card: result.card, variant: result.variant)
                        .scaleEffect(didAppear ? 1.0 : 0.97)
                        .opacity(didAppear ? 1.0 : 0.0)
                        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: didAppear)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            VariantBadge(variant: result.variant)
                            if result.wasNewCard {
                                Badge(text: "NEW CARD", background: .green.opacity(0.2), foreground: .green)
                            }
                            if result.wasNewVariantForCard {
                                Badge(text: "NEW VARIANT", background: .blue.opacity(0.2), foreground: .blue)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("人物: \(result.card.person)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if !result.card.background.isEmpty {
                            Text(result.card.background)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if !result.card.topics.isEmpty {
                            FlowTags(tags: result.card.topics)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .onAppear {
            didAppear = true
        }
    }
}
