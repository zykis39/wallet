import SwiftUI
import ComposableArchitecture
import FirebaseCore
import SwiftData

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

let container = SwiftDataContainerProvider.shared.container(inMemory: false)

@main
struct WalletApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var isTest: Bool {
        if let _ = NSClassFromString("XCTest") {
            return true
        } else {
            return false
        }
    }
    
    init() {
        #if DEBUG
        Atlantis.start()
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: Store(initialState: .initial) {
                WalletFeature()
//                    ._printChanges()
            })
            .modelContainer(container)
            .preferredColorScheme(.light)
        }
    }
}
