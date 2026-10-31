import SwiftUI
import Observation

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
