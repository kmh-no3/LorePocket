import SwiftUI
import Observation

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
