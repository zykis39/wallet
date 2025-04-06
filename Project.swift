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
            scripts: [
                .post(script: "/Users/artemzaitsev/projects/wallet/Tuist/.build/checkouts/firebase-ios-sdk/Crashlytics/run",
                      name: "crashlytics",
                      inputPaths: [
                        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}",
                        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}",
                        "${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist",
                        "$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist",
                        "$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)",
                      ])
            ],
            dependencies: [
                .external(name: "ComposableArchitecture"),
                .external(name: "FirebaseAnalytics"),
                .external(name: "FirebaseCrashlytics"),
                .external(name: "Alamofire"),
                .external(name: "Atlantis"),
            ],
            settings: .settings(base: [
                "OTHER_LDFLAGS": ["-ObjC"],
                "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
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
