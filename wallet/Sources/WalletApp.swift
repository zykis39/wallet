import SwiftUI
import ComposableArchitecture
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct WalletApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: .initial) {
                WalletFeature()
                    ._printChanges()
            })
            .preferredColorScheme(.light)
        }
    }
}
