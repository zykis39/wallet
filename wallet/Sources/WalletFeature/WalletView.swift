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
        VStack(alignment: .leading) {
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
                    AddButton(color: .green) {
                        store.send(.createNewItemTapped(.expenses))
                    }
                }
            }
            .scrollDisabled(true)
            .scrollClipDisabled()
            .zIndex(expensesDragging ? 1 : 0)
            
            Spacer()
        }
    }
}
