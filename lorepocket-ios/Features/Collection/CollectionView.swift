import SwiftUI
import Observation

struct CollectionView: View {
    let pack: Pack
    @Bindable var store: ProgressStore
    @State private var viewModel: CollectionViewModel

    init(pack: Pack, store: ProgressStore) {
        self.pack = pack
        self.store = store
        _viewModel = State(initialValue: CollectionViewModel(pack: pack, store: store))
    }

    var body: some View {
        @Bindable var vm = viewModel
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(vm.packTitle)
                        .font(.title2).bold()
                    Text(vm.progressText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)

            Picker("表示", selection: $vm.ownership) {
                Text("すべて").tag(CollectionOwnership.all)
                Text("所持").tag(CollectionOwnership.owned)
                Text("未所持").tag(CollectionOwnership.unowned)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .accessibilityLabel("所持で絞り込む")

            HStack {
                TextField("検索", text: $vm.query)
                    .textFieldStyle(.roundedBorder)

                Picker("並び", selection: $vm.sort) {
                    ForEach(CollectionViewModel.SortOption.allCases) { opt in
                        Text(opt.rawValue).tag(opt)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("並び順")
            }
            .padding(.horizontal)

            GeometryReader { proxy in
                let count = CollectionQuery.columnCount(containerWidth: proxy.size.width)
                let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
                ScrollView {
                    if vm.filteredItems.isEmpty {
                        ContentUnavailableView("該当するカードがありません", systemImage: "magnifyingglass")
                            .padding(.top, 32)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(vm.filteredItems) { item in
                                NavigationLink(value: item) {
                                    CardThumbnailView(item: item) {
                                        viewModel.toggleFavorite(cardId: item.cardId)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("コレクション")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: CardListItem.self) { item in
            CardDetailView(cardId: item.cardId, pack: pack, store: store)
        }
        .onAppear {
            viewModel.refresh()
        }
        .onChange(of: store.root) {
            viewModel.refresh()
        }
    }
}
