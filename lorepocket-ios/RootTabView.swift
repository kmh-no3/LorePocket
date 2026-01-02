import SwiftUI
import Observation

struct RootTabView: View {
    @Bindable var store: ProgressStore
    @Bindable var library: PackLibrary
    
    enum Tab: Hashable {
        case packs
        case collection
        case settings
    }
    
    @State private var tab: Tab = .packs
    
    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                PackListView(store: store, library: library)
            }
            .tabItem {
                Label("パック", systemImage: "square.stack.3d.up.fill")
            }
            .tag(Tab.packs)
            
            NavigationStack {
                CollectionsHomeView(store: store, library: library)
            }
            .tabItem {
                Label("図鑑", systemImage: "books.vertical.fill")
            }
            .tag(Tab.collection)
            
            NavigationStack {
                SettingsView(store: store, library: library)
            }
            .tabItem {
                Label("設定", systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
        }
    }
}

struct CollectionsHomeView: View {
    @Bindable var store: ProgressStore
    @Bindable var library: PackLibrary
    
    var body: some View {
        List {
            Section("パックを選択") {
                ForEach(library.packs) { pack in
                    NavigationLink {
                        CollectionView(pack: pack, store: store)
                    } label: {
                        PackRow(pack: pack, progress: store.progress(for: pack.id))
                    }
                }
            }
        }
        .navigationTitle("図鑑")
    }
}

struct SettingsView: View {
    @Bindable var store: ProgressStore
    @Bindable var library: PackLibrary
    
    @State private var showResetConfirm = false
    
    var body: some View {
        List {
            Section("データ") {
                Button(role: .destructive) {
                    showResetConfirm = true
                } label: {
                    Label("進捗をリセット", systemImage: "trash.fill")
                }
            }
            
            Section("アプリ") {
                HStack {
                    Text("LorePocket")
                    Spacer()
                    Text("MVP")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("インポート")
                    Spacer()
                    Text("Markdown / JSON（拡張中）")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("設定")
        .alert("進捗をリセットしますか？", isPresented: $showResetConfirm) {
            Button("キャンセル", role: .cancel) {}
            Button("リセット", role: .destructive) {
                store.resetAll()
            }
        } message: {
            Text("すべてのパックの所持状況と最終ドロー日が消えます。")
        }
    }
}


