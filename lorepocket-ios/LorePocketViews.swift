import SwiftUI
import Observation
import UniformTypeIdentifiers
import UIKit

struct PackListView: View {
    @Bindable var store: ProgressStore
    @Bindable var library: PackLibrary
    
    @State private var showResetConfirm = false
    @State private var showImport = false
    @State private var importErrorMessage: String? = nil
    
    var body: some View {
        List {
            Section {
                ForEach(library.packs) { pack in
                    NavigationLink(value: pack) {
                        PackRow(pack: pack, progress: store.progress(for: pack.id))
                    }
                }
            } header: {
                Text("パック")
            } footer: {
                Text("パックは端末内に保存されます（MVPはオフライン前提）。私的データはリポジトリに入れず、インポートで運用できます。")
            }
        }
        .navigationTitle("LorePocket")
        .navigationDestination(for: Pack.self) { pack in
            PackDetailView(pack: pack, store: store)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("インポート") { showImport = true }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("リセット") { showResetConfirm = true }
            }
        }
        .alert("進捗をリセットしますか？", isPresented: $showResetConfirm) {
            Button("キャンセル", role: .cancel) {}
            Button("リセット", role: .destructive) {
                store.resetAll()
            }
        } message: {
            Text("すべてのパックの所持状況と最終ドロー日が消えます。")
        }
        .fileImporter(
            isPresented: $showImport,
            allowedContentTypes: [UTType(filenameExtension: "md")!],
            allowsMultipleSelection: true
        ) { result in
            do {
                let urls = try result.get()
                try importWorldQuotes(urls: urls)
            } catch {
                importErrorMessage = "インポートに失敗しました（ファイル選択）。"
            }
        }
        .alert("インポートエラー", isPresented: Binding(get: { importErrorMessage != nil }, set: { if !$0 { importErrorMessage = nil } })) {
            Button("OK", role: .cancel) { importErrorMessage = nil }
        } message: {
            Text(importErrorMessage ?? "")
        }
    }
}

private extension PackListView {
    func importWorldQuotes(urls: [URL]) throws {
        // security scopedの可能性があるので、できる限りアクセス権を確保
        let scoped = urls.map { url -> (URL, Bool) in
            (url, url.startAccessingSecurityScopedResource())
        }
        defer {
            for (u, ok) in scoped where ok {
                u.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            try library.importWorldQuotesMarkdown(fileURLs: urls)
        } catch {
            importErrorMessage = "インポートに失敗しました（Markdown解析/保存）。\nテンプレ形式（frontmatter + 見出し）が一致しているか確認してください。"
        }
    }
}

struct PackRow: View {
    let pack: Pack
    let progress: PackProgress
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.tint.opacity(0.15))
                Image(systemName: "square.stack.3d.up.fill")
                    .foregroundStyle(.tint)
            }
            .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pack.meta.title)
                    .font(.headline)
                Text(pack.meta.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            PackProgressPill(pack: pack, progress: progress)
        }
        .padding(.vertical, 4)
    }
}

private struct PackProgressPill: View {
    let pack: Pack
    let progress: PackProgress
    
    private var ownedUniqueCardCount: Int {
        Set(progress.owned.map(\.cardId)).count
    }
    
    var body: some View {
        let total = max(pack.cards.count, 1)
        let pct = Double(ownedUniqueCardCount) / Double(total)
        
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(ownedUniqueCardCount)/\(pack.cards.count)")
                .font(.subheadline.weight(.semibold))
            ProgressView(value: pct)
                .frame(width: 72)
        }
    }
}

struct PackDetailView: View {
    let pack: Pack
    @Bindable var store: ProgressStore
    
    @State private var showBlockedAlert = false
    @State private var drawErrorMessage: String? = nil
    @State private var drawResult: DrawEngine.DrawResult? = nil
    @State private var isDrawing = false
    
    var body: some View {
        let progress = store.progress(for: pack.id)
        let stats = PackStats(pack: pack, progress: progress)
        let canDrawToday = store.canDrawToday(packId: pack.id)
        
        return List {
            packHeroSection(stats: stats, canDrawToday: canDrawToday)
            overviewSection()
            statusSection(progress: progress, stats: stats, canDrawToday: canDrawToday)
            actionsSection(progress: progress, canDrawToday: canDrawToday)
            variantOddsSection()
        }
        .navigationTitle(pack.meta.title)
        .navigationBarTitleDisplayMode(.inline)
        .alert("今日はすでに引いています", isPresented: $showBlockedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("明日また来てね。")
        }
        .alert("ドローエラー", isPresented: Binding(get: { drawErrorMessage != nil }, set: { if !$0 { drawErrorMessage = nil } })) {
            Button("OK", role: .cancel) { drawErrorMessage = nil }
        } message: {
            Text(drawErrorMessage ?? "")
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
    func actionsSection(progress: PackProgress, canDrawToday: Bool) -> some View {
        Section("操作") {
            Button {
                if !canDrawToday {
                    showBlockedAlert = true
                    return
                }
                Task { @MainActor in
                    guard !isDrawing else { return }
                    isDrawing = true
                    // ちょい演出：すぐ結果を出すと味気ないので短い待ち
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    var rng = SystemRandomNumberGenerator()
                    do {
                        let result = try DrawEngine.draw(pack: pack, progress: progress, now: Date(), rng: &rng)
                        store.recordDraw(packId: pack.id, ownedCard: result.ownedCard)
                        drawResult = result
                    } catch {
                        drawErrorMessage = "ドローできませんでした（パックのカード/バリアントが空です）。"
                    }
                    isDrawing = false
                }
            } label: {
                if isDrawing {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Draw中…")
                    }
                } else {
                    Label("Draw（1日1回）", systemImage: "sparkles")
                }
            }
            .disabled(isDrawing)

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

struct CollectionView: View {
    let pack: Pack
    @Bindable var store: ProgressStore
    
    @State private var query: String = ""
    @State private var filter: Filter = .owned
    @State private var sort: Sort = .day
    
    enum Filter: String, CaseIterable, Identifiable {
        case owned = "所持"
        case unowned = "未所持"
        case all = "全部"
        var id: String { rawValue }
    }
    
    enum Sort: String, CaseIterable, Identifiable {
        case day = "日付順"
        case person = "人物"
        case recent = "最近取得"
        var id: String { rawValue }
    }
    
    private var progress: PackProgress { store.progress(for: pack.id) }
    private var stats: PackStats { PackStats(pack: pack, progress: progress) }
    
    private var ownedByCard: [String: [OwnedCard]] {
        Dictionary(grouping: progress.owned, by: { $0.cardId })
    }
    
    private func dayNumber(from cardId: String) -> Int? {
        // packId-001 形式を想定
        let parts = cardId.split(separator: "-")
        guard let last = parts.last, let n = Int(last) else { return nil }
        return n
    }
    
    private var filteredCards: [Card] {
        var base: [Card] = {
            switch filter {
            case .owned:
                return pack.cards.filter { ownedByCard[$0.id] != nil }
            case .unowned:
                return pack.cards.filter { ownedByCard[$0.id] == nil }
            case .all:
                return pack.cards
            }
        }()
        
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !q.isEmpty {
            base = base.filter { card in
                card.text.localizedCaseInsensitiveContains(q)
                || card.person.localizedCaseInsensitiveContains(q)
                || card.background.localizedCaseInsensitiveContains(q)
                || card.genre.contains(where: { $0.localizedCaseInsensitiveContains(q) })
                || card.topics.contains(where: { $0.localizedCaseInsensitiveContains(q) })
            }
        }
        
        switch sort {
        case .day:
            return base.sorted {
                let a = dayNumber(from: $0.id) ?? Int.max
                let b = dayNumber(from: $1.id) ?? Int.max
                if a != b { return a < b }
                return $0.id < $1.id
            }
        case .person:
            return base.sorted {
                if $0.person != $1.person { return $0.person < $1.person }
                return $0.id < $1.id
            }
        case .recent:
            return base.sorted {
                let a = stats.lastObtainedAt(for: $0.id) ?? .distantPast
                let b = stats.lastObtainedAt(for: $1.id) ?? .distantPast
                if a != b { return a > b }
                return $0.id < $1.id
            }
        }
    }
    
    var body: some View {
        List {
            Section {
                Picker("フィルタ", selection: $filter) {
                    ForEach(Filter.allCases) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section {
                Picker("ソート", selection: $sort) {
                    ForEach(Sort.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section("進捗") {
                HStack {
                    Text("カード")
                    Spacer()
                    Text("\(stats.ownedUniqueCards)/\(stats.totalCards)")
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: stats.cardCompletion)
                
                HStack {
                    Text("別柄（バリアント）")
                    Spacer()
                    Text("\(stats.ownedUniquePairs)/\(stats.totalPossiblePairs)")
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: stats.variantCompletion)
            }
            
            Section {
                ForEach(filteredCards) { card in
                    NavigationLink {
                        CardDetailView(card: card, pack: pack, owned: ownedByCard[card.id] ?? [])
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(card.text)
                                .font(.body)
                                .lineLimit(2)
                            Text(card.person)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            let ownedVariants = stats.ownedVariants(for: card.id)
                            if !ownedVariants.isEmpty || filter == .all {
                                Text("別柄: \(ownedVariants.count)/\(stats.totalVariants)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } footer: {
                Text("検索は本文・人物・背景・ジャンル・Topicsを対象にします。")
            }
        }
        .navigationTitle("コレクション")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "検索（本文/人物/背景/ジャンル/Topics）")
    }
}

struct CardDetailView: View {
    let card: Card
    let pack: Pack
    let owned: [OwnedCard]
    
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

// MARK: - UI Components

private struct CardView: View {
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

private struct VariantBadge: View {
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

private struct Badge: View {
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

private struct FlowTags: View {
    let tags: [String]
    
    var body: some View {
        // MVP: 簡易表示（折返しは自然に任せる）
        Text(tags.map { "#\($0)" }.joined(separator: "  "))
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}


