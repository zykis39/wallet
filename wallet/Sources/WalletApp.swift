import SwiftUI
import ComposableArchitecture

@main
struct WalletApp: App {
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: .initial) { WalletFeature() })
        }
    }
}
