import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    let store: StoreOf<WalletFeature>
    
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
    
    @State private var draggingWalletItemData: WalletItemPreferenceData = .empty
    private var expensesDragging: Bool {
        guard let item = draggingWalletItemData.item else { return false }
        return store.expences.contains(item)
    }
    private var droppingWalletItem: WalletItem? {
        guard let _ = draggingWalletItemData.item else { return nil }
        let location = draggingWalletItemData.location
        // find WalletItemView using location
        
        return nil
    }

    public var body: some View {
        VStack(alignment: .leading) {
            // FIXME: wrap into TabView, fix clipping
            HStackEqualSpacingLayout(columnsNumber: Constants.elementsInRow, minElementWidth: Constants.minColumnWidth, maxElementWidth: Constants.maxColumnWidth) {
                ForEach(accountPages[0]!) { pageItem in
                    WalletItemView(item: pageItem, highlighted: pageItem == draggingWalletItemData.item)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: 100)
            .zIndex(expensesDragging ? 0 : 1)
            .border(.red)
            
            ScrollView(.vertical) {
                LazyVGrid(columns: accountColumns, alignment: .center, spacing: Constants.rowSpacing) {
                    ForEach(store.expences, id: \.id) { item in
                        WalletItemView(item: item, highlighted: item == draggingWalletItemData.item)
                    }
                }
            }
            .scrollDisabled(true)
            .scrollClipDisabled()
            .zIndex(expensesDragging ? 1 : 0)
            .border(.green)
        }
        .coordinateSpace(name: "WalletSpace")
        .onPreferenceChange(WalletItemPreferenceKey.self) { value in
            if let item = value.item {
                print("preference changed: \(item.name), globalLocation: \(value.location)")
            }
            draggingWalletItemData = value
        }
        .coordinateSpace(name: "WalletSpace")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(initialState: WalletFeature.State(accounts: WalletItem.defaultAccounts, expences: WalletItem.defaultExpenses)) { WalletFeature()
        })
    }
}
