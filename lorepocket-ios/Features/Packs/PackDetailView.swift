import SwiftUI
import Observation
import UIKit

struct PackDetailView: View {
    let pack: Pack
    @Bindable var store: ProgressStore
    
    @State private var showBlockedAlert = false
    @State private var openingPack: Pack?
    @State private var drawResult: DrawEngine.DrawResult? = nil
    
    var body: some View {
        let progress = store.progress(for: pack.id)
        let stats = PackStats(pack: pack, progress: progress)
        let canDrawToday = store.canDrawToday(packId: pack.id)
        
        return List {
            packHeroSection(stats: stats, canDrawToday: canDrawToday)
            overviewSection()
            statusSection(progress: progress, stats: stats, canDrawToday: canDrawToday)
            actionsSection(canDrawToday: canDrawToday)
            variantOddsSection()
        }
        .navigationTitle(pack.meta.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("今日はすでに引いています", isPresented: $showBlockedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("明日また来てね。")
        }
        .drawOpening(pack: $openingPack, store: store) { _, result in
            drawResult = result
        }
        .sheet(item: $drawResult) { result in
            DrawResultView(pack: pack, result: result, store: store)
        }
    }
}

private extension PackDetailView {
    @ViewBuilder
    func packHeroSection(stats: PackStats, canDrawToday: Bool) -> some View {
        Section {
            VStack(spacing: 12) {
                // 上部サムネ列（将来: 別柄/別アート/期間限定など）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(0..<5, id: \.self) { idx in
                            PackThumbView(pack: pack, index: idx)
                        }
                    }
                    .padding(.horizontal, 6)
                }
                
                // メインカバー
                PackCoverHeroView(pack: pack)
                    .padding(.horizontal, 6)
                
                // 主要ステータス
                HStack(spacing: 10) {
                    Label("\(stats.ownedUniqueCards)/\(stats.totalCards)", systemImage: "checklist")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    Label("\(stats.ownedUniquePairs)/\(stats.totalPossiblePairs)", systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(canDrawToday ? "今日引ける" : "今日は消化済み")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(canDrawToday ? .green : .secondary)
                }
                .padding(.horizontal, 6)
            }
            .padding(.vertical, 6)
            .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
        }
        .textCase(nil)
    }
    
    @ViewBuilder
    func overviewSection() -> some View {
        Section("概要") {
            Text(pack.meta.description)
                .font(.body)

            if !pack.meta.tags.isEmpty {
                FlowTags(tags: pack.meta.tags)
                    .padding(.vertical, 2)
            }
        }
    }

    @ViewBuilder
    func statusSection(progress: PackProgress, stats: PackStats, canDrawToday: Bool) -> some View {
        let ownedUniqueCardCount = Set(progress.owned.map(\.cardId)).count
        let progressPercent: Double = {
            let total = max(pack.cards.count, 1)
            return Double(ownedUniqueCardCount) / Double(total)
        }()

        Section("状態") {
            HStack {
                Label("今日のドロー", systemImage: canDrawToday ? "checkmark.seal.fill" : "clock.fill")
                    .foregroundStyle(canDrawToday ? .green : .secondary)
                Spacer()
                Text(canDrawToday ? "可能" : "消化済み")
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text("進捗")
                Spacer()
                Text("\(ownedUniqueCardCount)/\(pack.cards.count)")
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progressPercent)

            HStack {
                Text("別柄（バリアント）")
                Spacer()
                Text("\(stats.ownedUniquePairs)/\(stats.totalPossiblePairs)")
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: stats.variantCompletion)

            if let last = progress.lastDrawDate {
                HStack {
                    Text("最終ドロー")
                    Spacer()
                    Text(last, style: .date)
                        .foregroundStyle(.secondary)
                }
            }

            if !canDrawToday, let last = progress.lastDrawDate, let next = nextDrawDate(fromLastDraw: last) {
                HStack {
                    Text("次に引ける日")
                    Spacer()
                    Text(next, style: .date)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text("ドロー回数")
                Spacer()
                Text("\(progress.drawCount)")
                    .foregroundStyle(.secondary)
            }

            if stats.isVariantComplete {
                Text("バリアントまでコンプリート！")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
            } else if stats.isCardComplete {
                Text("カードはコンプリート。別柄コンプを狙えます。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("未所持カード: \(stats.remainingUnownedCards)枚")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    func actionsSection(canDrawToday: Bool) -> some View {
        Section("操作") {
            Button {
                if !canDrawToday {
                    showBlockedAlert = true
                    return
                }
                openingPack = pack
            } label: {
                Label("Draw（1日1回）", systemImage: "sparkles")
            }
            .disabled(openingPack != nil)

            NavigationLink {
                CollectionView(pack: pack, store: store)
            } label: {
                Label("コレクション", systemImage: "books.vertical.fill")
            }
        }
    }

    @ViewBuilder
    func variantOddsSection() -> some View {
        Section {
            let totalWeight = max(pack.variants.map(\.weight).reduce(0, +), 1)
            ForEach(pack.variants) { v in
                let pct = Int((Double(v.weight) / Double(totalWeight)) * 100)
                HStack {
                    VariantBadge(variant: v)
                    Spacer()
                    Text("\(pct)%")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("バリアント確率")
        } footer: {
            Text("未所持バリアントがある場合は、その中から優先して抽選します（MVP仕様）。")
        }
    }

    func nextDrawDate(fromLastDraw last: Date) -> Date? {
        let cal = Calendar.current
        let start = cal.startOfDay(for: last)
        return cal.date(byAdding: .day, value: 1, to: start)
    }
}

private struct PackThumbView: View {
    let pack: Pack
    let index: Int
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(thumbBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
            
            Image(systemName: index == 0 ? "sparkles" : "photo")
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(width: 58, height: 58)
    }
    
    private var thumbBackground: some ShapeStyle {
        LinearGradient(
            colors: [seedColor.opacity(0.55), seedColor.opacity(0.25)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var seedColor: Color {
        let v = abs(pack.id.hashValue % 360)
        return Color(hue: Double(v) / 360.0, saturation: 0.55, brightness: 0.85)
    }
}

private struct PackCoverHeroView: View {
    let pack: Pack
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(heroBackground)
                .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 10)
            
            if let img = PackCoverProvider.coverImage(packId: pack.id) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    )
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(pack.meta.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 12)
                }
            }
        }
        .frame(height: 220)
    }
    
    private var heroBackground: some ShapeStyle {
        let v = abs(pack.id.hashValue % 360)
        let c = Color(hue: Double(v) / 360.0, saturation: 0.55, brightness: 0.85)
        return LinearGradient(
            colors: [c.opacity(0.95), c.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
