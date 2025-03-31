import ProjectDescription

let project = Project(
    name: "wallet",
    targets: [
        .target(
            name: "wallet",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.wallet",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["wallet/Sources/**"],
            resources: ["wallet/Resources/**"],
            dependencies: [
                .external(name: "PinLayout"),
                .external(name: "ComposableArchitecture"),
                .external(name: "FirebaseAnalytics"),
            ]
        ),
        .target(
            name: "walletTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.walletTests",
            infoPlist: .default,
            sources: ["wallet/Tests/**"],
            resources: [],
            dependencies: [.target(name: "wallet")]
        ),
    ]
)
