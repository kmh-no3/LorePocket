import SwiftUI
import Observation

struct CollectionView: View {
    let pack: Pack
    @Bindable var store: ProgressStore
    @State private var viewModel: CollectionViewModel

    private var columns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    }

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

            HStack {
                TextField("検索", text: $vm.query)
                    .textFieldStyle(.roundedBorder)

                Picker("", selection: $vm.sort) {
                    ForEach(CollectionViewModel.SortOption.allCases) { opt in
                        Text(opt.rawValue).tag(opt)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal)

            ScrollView {
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
