import SwiftUI
import ComposableArchitecture

struct WalletView: View {
    var store: StoreOf<WalletFeature>
    
    public init(store: StoreOf<WalletFeature>) {
        self.store = store
        calculateAccountPages()
    }
    
    private struct Constants {
        static let elementsInRow: Int = 4
        static let minColumnWidth: CGFloat = 40
        static let maxColumnWidth: CGFloat = 120
        static let rowSpacing: CGFloat = 12
    }
    
    private var balance: Double {
        store.state.accounts.reduce(0) { $0 + $1.balance }
    }
    private var expenses: Double {
        store.state.transactions
            .filter { $0.destination.type == .expenses }
            .filter { $0.timestamp.isEqual(to: .now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var accountColumns: [GridItem] = Array(repeatElement(GridItem(.flexible(minimum: Constants.minColumnWidth, maximum: Constants.maxColumnWidth)), count: Constants.elementsInRow))
    
    private var accountPages: [Int: [WalletItem]] = [:]
    private mutating func calculateAccountPages() {
        for (index, item) in store.accounts.enumerated() {
            let page = index / Constants.elementsInRow
            var pageItems = accountPages[page, default: []]
            pageItems.append(item)
            accountPages[page] = pageItems
        }
    }
    
    private var expensesDragging: Bool {
        guard let item = store.state.dragItem else { return false }
        return store.expenses.contains(item)
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            HeaderWallet(balance: balance,
                         expenses: expenses,
                         leftSystemImageName: "info.square.fill",
                         rightSystemImageName: "chart.bar.xaxis",
                         leftAction: { store.send(.aboutAppPresentedChanged(true)) },
                         rightAction: { store.send(.expensesStatisticsPresentedChanged(true)) },
                         imageSize: 24)
            .frame(maxHeight: 44)
            
            Divider()
            // FIXME: wrap into TabView, fix clipping
            HStackEqualSpacingLayout(columnsNumber: Constants.elementsInRow, minElementWidth: Constants.minColumnWidth, maxElementWidth: Constants.maxColumnWidth) {
                ForEach(accountPages[0] ?? [], id: \.self) { pageItem in
                    WalletItemView(store: store, item: pageItem)
                        .zIndex(store.state.dragItem == pageItem ? 1 : 0)
                }
                AddButton(color: .yellow) {
                    store.send(.createNewItemTapped(.account))
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: 100)
            .zIndex(expensesDragging ? 0 : 1)
            
            Divider()
            
            ScrollView(.vertical) {
                LazyVGrid(columns: accountColumns, alignment: .center, spacing: Constants.rowSpacing) {
                    ForEach(store.expenses, id: \.self) { item in
                        WalletItemView(store: store, item: item)
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
        .coordinateSpace(name: "WalletSpace")
    }
}
