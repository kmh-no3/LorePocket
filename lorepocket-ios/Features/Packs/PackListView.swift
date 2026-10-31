import SwiftUI
import Observation
import UniformTypeIdentifiers

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
