import SwiftUI
import ComposableArchitecture

@main
struct WalletApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(store: Store(initialState: WalletFeature.State(accounts: WalletItem.defaultAccounts, expences: WalletItem.defaultExpenses)) { WalletFeature()
            })
        }
    }
}
