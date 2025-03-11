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
    
    private var accountColumns: [GridItem] = [
        GridItem(.flexible(minimum: Constants.minColumnWidth, maximum: Constants.maxColumnWidth)),
        GridItem(.flexible(minimum: Constants.minColumnWidth, maximum: Constants.maxColumnWidth)),
        GridItem(.flexible(minimum: Constants.minColumnWidth, maximum: Constants.maxColumnWidth)),
        GridItem(.flexible(minimum: Constants.minColumnWidth, maximum: Constants.maxColumnWidth)),
    ]
    
    private var accountPages: [Int: [WalletItem]] = [:]
    private mutating func calculateAccountPages() {
        for (index, item) in store.accounts.enumerated() {
            let page = index / Constants.elementsInRow
            var pageItems = accountPages[page, default: []]
            pageItems.append(item)
            accountPages[page] = pageItems
        }
    }

    public var body: some View {
        VStack(alignment: .leading) {
            TabView {
                ForEach(0 ..< accountPages.keys.count) { page in
                    HStackEqualSpacingLayout(columnsNumber: Constants.elementsInRow, minElementWidth: Constants.minColumnWidth, maxElementWidth: Constants.maxColumnWidth) {
                        ForEach(accountPages[page] ?? []) { pageItem in
                            WalletItemView(item: pageItem)
                        }
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: 100)
            .border(.red)
            
            ScrollView(.vertical) {
                LazyVGrid(columns: accountColumns, alignment: .center, spacing: Constants.rowSpacing) {
                    ForEach(store.expences) { item in
                        WalletItemView(item: item)
                    }
                }
            }
            .scrollDisabled(true)
            .border(.green)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(store: Store(initialState: WalletFeature.State(accounts: WalletItem.defaultAccounts, expences: WalletItem.defaultExpenses)) { WalletFeature()
        })
    }
}
