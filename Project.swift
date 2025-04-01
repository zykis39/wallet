import ProjectDescription

let project = Project(
    name: "wallet",
    targets: [
        .target(
            name: "wallet",
            destinations: .iOS,
            product: .app,
            bundleId: "com.zykis.wallet",
            infoPlist: .file(path: "wallet/Resources/wallet-Info.plist"),
            sources: ["wallet/Sources/**"],
            resources: ["wallet/Resources/**"],
            dependencies: [
                .external(name: "ComposableArchitecture"),
                .external(name: "FirebaseAnalytics"),
            ],
            settings: .settings(base: [
                "OTHER_LDFLAGS": ["-ObjC"]
            ]),
            launchArguments: [.launchArgument(name: "-FIRDebugEnabled", isEnabled: true)]
        ),
        .target(
            name: "walletTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.zykis.walletTests",
            infoPlist: .default,
            sources: ["wallet/Tests/**"],
            resources: [],
            dependencies: [.target(name: "wallet")]
        ),
    ]
)
