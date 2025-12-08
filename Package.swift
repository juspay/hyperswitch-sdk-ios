// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Hyperswitch",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "HyperswitchAuthentication",
            targets: ["HyperswitchAuthentication"]
        )
    ],
    targets: [
        .target(
            name: "HyperswitchAuthentication",
            path: "hyperswitchSDK",
            exclude: ["Core", "CoreLite"],
            sources: ["AuthenticationModule", "Shared"]
        )
    ]
)
