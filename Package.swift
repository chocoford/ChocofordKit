// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChocofordKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15), .watchOS(.v6), .macOS(.v12), .visionOS(.v1)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "ChocofordUI", targets: ["ChocofordUI", "ChocofordEssentials"]),
        .library(name: "ChocofordEssentials", targets: ["ChocofordEssentials"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git", .upToNextMajor(from: "6.2.0")),
        .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", .upToNextMajor(from: "1.3.0")),
        .package(url: "https://github.com/ohitsdaniel/ShapeBuilder.git", from: "0.1.0"),
        .package(url: "https://github.com/chocoford/SwiftyAlert.git", branch: "dev"),
        .package(url: "https://github.com/markiv/SwiftUI-Shimmer.git", .upToNextMajor(from: "1.5.1")),
        .package(url: "https://github.com/stevengharris/SplitView.git", from: "3.0.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "8.3.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ChocofordUI",
            dependencies: [
                "ChocofordEssentials",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SwiftUIIntrospect", package: "SwiftUI-Introspect"),
                "SFSafeSymbols",
                "ShapeBuilder",
                "SwiftyAlert",
                .product(name: "Shimmer", package: "SwiftUI-Shimmer"),
                "SplitView",
                "Kingfisher"
            ],
            path: "Sources/UI",
            resources: [.process("Resources")],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "ChocofordEssentials",
            dependencies: [],
            path: "Sources/Essentials"
        ),
//        .testTarget(
//            name: "ChocofordUITests",
//            dependencies: ["ChocofordUI"]),
    ]
)
