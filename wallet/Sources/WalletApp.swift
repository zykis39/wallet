import SwiftUI
import ComposableArchitecture
import FirebaseCore

#if DEBUG
import Atlantis
#endif

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
    
    init() {
        #if DEBUG
        Atlantis.start()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: .initial) {
                WalletFeature()
            })
            .modelContainer(SwiftDataContainerProvider.shared.container)
            .preferredColorScheme(.light)
        }
    }
}
