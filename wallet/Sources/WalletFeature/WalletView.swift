import SwiftUI
import ComposableArchitecture

struct WalletView: View {
    @Bindable var store: StoreOf<WalletFeature>
    
    public init(store: StoreOf<WalletFeature>) {
        self.store = store
    }
    
    private struct Constants {
        static let elementsInRow: Int = 4
        static let minColumnWidth: CGFloat = 80
        static let rowSpacing: CGFloat = 12
    }

    private let expensesColumns: [GridItem] = Array(repeatElement(GridItem(.flexible(minimum: Constants.minColumnWidth, maximum: .greatestFiniteMagnitude)), count: Constants.elementsInRow))
    private var expensesDragging: Bool {
        guard let item = store.state.dragItem else { return false }
        return store.expenses.contains(item)
    }
    
    public var body: some View {
        ZStack {
            VStack(alignment: .center) {
                HeaderWallet(balance: store.state.balance,
                             expenses: store.state.monthExpenses,
                             currency: store.state.selectedCurrency,
                             leftSystemImageName: "gearshape.fill",
                             rightSystemImageName: "chart.bar.xaxis",
                             leftAction: { store.send(.settingsPresentedChanged(true)) },
                             rightAction: { store.send(.presentSpendings) },
                             imageSize: 24)
                .frame(maxHeight: 44)
                
                Divider()
                
                AccountsView(store: store)
                    .frame(maxHeight: 120)
                    .zIndex(expensesDragging ? 0 : 1)
                
                Divider()
                
                ScrollView(.vertical) {
                    LazyVGrid(columns: expensesColumns, alignment: .center, spacing: Constants.rowSpacing) {
                        ForEach(store.expenses, id: \.self) { item in
                            WalletItemView(store: store,
                                           item: item)
                        }
                        AddButton(color: .green) { [weak store] in
                            store?.send(.createNewItemTapped(.expenses))
                        }
                    }
                }
                .scrollDisabled(true)
                .scrollClipDisabled()
                .zIndex(expensesDragging ? 1 : 0)
                
                Spacer()
                Button { [weak store] in
                    guard let store else { return }
                    switch store.state.dragMode {
                    case .normal:
                        store.send(.dragModeChanged(.reordering))
                    case .reordering:
                        store.send(.dragModeChanged(.normal))
                    }
                } label: {
                    switch store.state.dragMode {
                    case .normal:
                        Image(systemName: "square.grid.3x3.square")
                            .resizable()
                            .frame(width: 28, height: 28, alignment: .center)
                            .foregroundStyle(.white)
                    case .reordering:
                        Text("Done")
                            .frame(minWidth: 120)
                    }
                }
                .buttonStyle(.bordered)
            }
            .onTapGesture { [weak store] in
                store?.send(.dragModeChanged(.normal))
            }
            
            /*
            let frame = store.state.itemFrames[store.dragItem?.id ?? UUID(), default: .zero]
            let framePos: CGPoint = .init(x: frame.origin.x + frame.width / 2,
                                          y: frame.origin.y + frame.height / 2)
            let offsetFromCenter: CGSize = .init(width: framePos.x - store.state.draggingStartLocation.x,
                                                 height: framePos.y - store.state.draggingStartLocation.y)
             */
            
            // WalletItemView for dragging
            WalletItemView(store: store, item: store.state.dragItem ?? .none)
                .opacity((store.state.dragItem != nil && store.state.dragMode == .reordering) ? 1 : 0)
                .position(x: store.state.draggingLocation.x/* + offsetFromCenter.width*/,
                          y: store.state.draggingLocation.y/* + offsetFromCenter.height*/)
//                .animation(.easeInOut.speed(4), value: store.state.draggingLocation)
        }.coordinateSpace(name: "WalletSpace")
    }
}
