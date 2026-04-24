// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CapacitorZendeskClassicSdk",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "CapacitorZendeskClassicSdk",
            targets: ["CapacitorZendeskSupportSdk", "CapacitorZendeskSupportSdkObjc"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0"),
        .package(url: "https://github.com/zendesk/support_sdk_ios", exact: "8.0.4"),
        .package(url: "https://github.com/zendesk/messaging_sdk_ios", from: "6.0.0")
    ],
    targets: [
        .target(
            name: "CapacitorZendeskSupportSdk",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "ZendeskSupportSDK", package: "support_sdk_ios"),
                .product(name: "ZendeskMessagingSDK", package: "messaging_sdk_ios")
            ],
            path: "ios/CapacitorZendeskSupportSdk/Source/CapacitorZendeskSupportSdk"
        ),
        .target(
            name: "CapacitorZendeskSupportSdkObjc",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                "CapacitorZendeskSupportSdk"
            ],
            path: "ios/CapacitorZendeskSupportSdk/Source/CapacitorZendeskSupportSdkObjc",
            publicHeadersPath: "."
        )
    ]
)
