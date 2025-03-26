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

struct WalletView: View {
    var store: StoreOf<WalletFeature>
    var geometry: GeometryProxy
    
    public init(store: StoreOf<WalletFeature>, geometry: GeometryProxy) {
        self.store = store
        self.geometry = geometry
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
    
    private var expensesDragging: Bool {
        guard let item = store.state.dragItem else { return false }
        return store.expences.contains(item)
    }
    
    public var body: some View {
        VStack(alignment: .leading) {
            // FIXME: wrap into TabView, fix clipping
            HStackEqualSpacingLayout(columnsNumber: Constants.elementsInRow, minElementWidth: Constants.minColumnWidth, maxElementWidth: Constants.maxColumnWidth) {
                ForEach(accountPages[0]!) { pageItem in
                    WalletItemView(store: store, item: pageItem, geometry: geometry)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: 100)
            .zIndex(expensesDragging ? 0 : 1)
            .border(.red)
            
            ScrollView(.vertical) {
                LazyVGrid(columns: accountColumns, alignment: .center, spacing: Constants.rowSpacing) {
                    ForEach(store.expences, id: \.id) { item in
                        WalletItemView(store: store, item: item, geometry: geometry)
                    }
                }
            }
            .scrollDisabled(true)
            .scrollClipDisabled()
            .zIndex(expensesDragging ? 1 : 0)
            .border(.green)
        }
        .coordinateSpace(name: "WalletSpace")
    }
}
