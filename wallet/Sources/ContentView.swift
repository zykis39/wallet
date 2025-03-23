import SwiftUI
import ComposableArchitecture

private struct DropItemKey: EnvironmentKey {
    typealias Value = WalletItem?
    
    static let defaultValue: Value = nil
}

extension EnvironmentValues {
    var dropItem: WalletItem? {
        get { self[DropItemKey.self] }
        set {
            guard let item = newValue else { return }
            self[DropItemKey.self] = item
        }
    }
}

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
    
    @State private var draggingWalletItemData: WalletItemDragPreferenceData = .empty
    @State private var droppingWalletItemData: WalletItemDropPreferenceData = .init(item: nil)
    
    private var expensesDragging: Bool {
        guard let item = draggingWalletItemData.item else { return false }
        return store.expences.contains(item)
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            // FIXME: wrap into TabView, fix clipping
            HStackEqualSpacingLayout(columnsNumber: Constants.elementsInRow, minElementWidth: Constants.minColumnWidth, maxElementWidth: Constants.maxColumnWidth) {
                ForEach(accountPages[0]!) { pageItem in
                    WalletItemView(item: pageItem, highlighted: pageItem == draggingWalletItemData.item, globalDropLocation: draggingWalletItemData.location)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: 100)
            .zIndex(expensesDragging ? 0 : 1)
            .border(.red)
            
            ScrollView(.vertical) {
                LazyVGrid(columns: accountColumns, alignment: .center, spacing: Constants.rowSpacing) {
                    ForEach(store.expences, id: \.id) { item in
                        WalletItemView(item: item, highlighted: item == draggingWalletItemData.item, globalDropLocation: draggingWalletItemData.location)
                    }
                }
            }
            .scrollDisabled(true)
            .scrollClipDisabled()
            .zIndex(expensesDragging ? 1 : 0)
            .border(.green)
        }
        .onPreferenceChange(WalletItemDragPreferenceKey.self) { value in
            draggingWalletItemData = value
        }
        .onPreferenceChange(WalletItemDropPreferenceKey.self) { value in
            droppingWalletItemData = value
        }
        .environment(\.dropItem, droppingWalletItemData.item)
        .coordinateSpace(name: "WalletSpace")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(initialState: WalletFeature.State(accounts: WalletItem.defaultAccounts, expences: WalletItem.defaultExpenses)) { WalletFeature()
        })
    }
}
