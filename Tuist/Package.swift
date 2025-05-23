// swift-tools-version: 5.9
@preconcurrency import PackageDescription

#if TUIST
@preconcurrency import ProjectDescription

    let packageSettings = PackageSettings(
        productTypes: [
            "ComposableArchitecture": .framework,
            "Alamofire": .framework,
            "Atlantis": .framework,
            "AppsFlyerLib": .staticLibrary
        ]
    )
#endif

let package = Package(
    name: "wallet",
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.18.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", exact: "11.10.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", exact: "5.10.0"),
        .package(url: "https://github.com/ProxymanApp/atlantis", exact: "1.27.0"),
        .package(url: "https://github.com/AppsFlyerSDK/AppsFlyerFramework", exact: "6.17.0"),
    ]
)
