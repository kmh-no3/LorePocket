import SwiftUI
import Observation

struct HomeView: View {
    @Bindable var store: ProgressStore
    @Bindable var library: PackLibrary
    var onOpenPacks: () -> Void

    @State private var selectedPackID: String?
    @State private var openingPack: Pack?
    @State private var drawResult: DrawEngine.DrawResult?

    var body: some View {
        Group {
            if library.packs.isEmpty {
                emptyState
            } else if let pack = selectedPack {
                featured(pack)
            }
        }
        .onChange(of: library.packs.map(\.id)) {
            if let selectedPackID, !library.packs.contains(where: { $0.id == selectedPackID }) {
                self.selectedPackID = nil
            }
        }
        .navigationTitle("今日のドロー")
        .navigationBarTitleDisplayMode(.inline)
        .drawOpening(pack: $openingPack, store: store) { _, result in
            drawResult = result
        }
        .sheet(item: $drawResult) { result in
            if let pack = pack(for: result) {
                DrawResultView(pack: pack, result: result, store: store)
            }
        }
    }

    private var featuredPack: Pack? {
        HomePackSelection.featured(in: library.packs) { store.canDrawToday(packId: $0) }
    }

    private var selectedPack: Pack? {
        if let selectedPackID, let pack = library.packs.first(where: { $0.id == selectedPackID }) {
            return pack
        }
        return featuredPack
    }

    private var selection: Binding<String?> {
        Binding(
            get: { selectedPackID ?? featuredPack?.id },
            set: { selectedPackID = $0 }
        )
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("パックがありません", systemImage: "square.stack.3d.up")
        } description: {
            Text("パックを取り込むと、今日の一枚を引けます。")
        } actions: {
            Button("パックを見る", action: onOpenPacks)
                .buttonStyle(.borderedProminent)
        }
    }

    private func featured(_ pack: Pack) -> some View {
        let progress = store.progress(for: pack.id)
        let stats = PackStats(pack: pack, progress: progress)
        let canDraw = store.canDrawToday(packId: pack.id)

        return GeometryReader { proxy in
            let width = CGFloat(CarouselMetrics.cardWidth(containerWidth: proxy.size.width))
            VStack(spacing: 16) {
                Spacer(minLength: 4)
                PackCarouselView(
                    packs: library.packs,
                    selection: selection,
                    canDraw: { store.canDrawToday(packId: $0.id) }
                )
                .frame(height: min(max(220, proxy.size.height * 0.52), 460))
                status(pack: pack, stats: stats, progress: progress, canDraw: canDraw)
                    .frame(maxWidth: min(width, proxy.size.width - 40))
                Spacer(minLength: 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actions(pack: pack, canDraw: store.canDrawToday(packId: pack.id))
        }
    }

    private func status(pack: Pack, stats: PackStats, progress: PackProgress, canDraw: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(pack.meta.title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
            Text(canDraw ? "今日引ける" : "今日は消化済み")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(canDraw ? Color.green : Color.secondary)
            Text("所持 \(stats.ownedUniqueCards)/\(stats.totalCards) · 収集率 \(completionPercent(stats))%")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if !canDraw, let last = progress.lastDrawDate, let next = nextDrawDate(from: last) {
                Text("次に引ける日 \(next.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func actions(pack: Pack, canDraw: Bool) -> some View {
        VStack(spacing: 10) {
            Button {
                openingPack = pack
            } label: {
                Label(canDraw ? "引く（1日1回）" : "明日また", systemImage: canDraw ? "sparkles" : "clock")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canDraw || openingPack != nil)
            .accessibilityLabel(canDraw ? "\(pack.meta.title) を引く" : "\(pack.meta.title) は今日は引けません")

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

    private func pack(for result: DrawEngine.DrawResult) -> Pack? {
        library.packs.first { $0.cards.contains(where: { $0.id == result.card.id }) }
    }

    private func completionPercent(_ stats: PackStats) -> Int {
        Int((stats.cardCompletion * 100).rounded())
    }

    private func nextDrawDate(from last: Date) -> Date? {
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: last))
    }
}
