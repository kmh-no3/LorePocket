import SwiftUI
import Observation

struct RootTabView: View {
    @Bindable var store: ProgressStore
    @Bindable var library: PackLibrary
    
    enum Tab: Hashable {
        case home
        case packs
        case collection
        case settings
    }
    
    @State private var tab: Tab = .home
    
    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                HomeView(store: store, library: library) {
                    tab = .packs
                }
            }
            .tabItem {
                Label("ホーム", systemImage: "house.fill")
            }
            .tag(Tab.home)

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
        .environment(\.returnHome) {
            tab = .home
        }
    }
}
