// swift-tools-version: 5.9
@preconcurrency import PackageDescription

#if TUIST
@preconcurrency import ProjectDescription

    let packageSettings = PackageSettings(
        // Customize the product types for specific package product
        // Default is .staticFramework
        // productTypes: ["Alamofire": .framework,] 
        productTypes: [
            "PinLayout": .framework,
            "ComposableArchitecture": .framework,
        ]
    )
#endif

let package = Package(
    name: "wallet",
    dependencies: [
        .package(url: "https://github.com/layoutBox/PinLayout", exact: "1.10.5"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", exact: "1.18.0"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk", exact: "11.10.0"),
        // Add your own dependencies here:
        // .package(url: "https://github.com/Alamofire/Alamofire", from: "5.0.0"),
        // You can read more about dependencies here: https://docs.tuist.io/documentation/tuist/dependencies
    ]
)
