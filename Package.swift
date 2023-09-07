// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChocofordKit",
    platforms: [
        .iOS(.v15), .watchOS(.v6), .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "ChocofordUI", targets: ["ChocofordUI", "ChocofordEssentials"]),
        .library(name: "ChocofordEssentials", targets: ["ChocofordEssentials"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
            url: "https://github.com/ohitsdaniel/ShapeBuilder.git",
            from: "0.1.0"
        ),
        .package(url: "https://github.com/markiv/SwiftUI-Shimmer.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/kirualex/SwiftyGif.git",
                 from: "5.4.4"),
        .package(url: "https://github.com/siteline/SwiftUI-Introspect.git", from: "0.12.0"),
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "2.2.2"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.8.1"),
        .package(url: "https://github.com/elai950/AlertToast.git", branch: "master"),
        .package(url: "https://github.com/stevengharris/SplitView.git", from: "3.0.0"),
        .package(url: "https://github.com/fatbobman/SwiftUIOverlayContainer.git", from: "2.0.0"),
        .package(url: "https://github.com/lucaszischka/BottomSheet", from: "3.1.0"),
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git", .upToNextMajor(from: "4.1.1"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ChocofordUI",
            dependencies: [
                "ChocofordEssentials",
                "ShapeBuilder",
                .product(name: "Shimmer", package: "SwiftUI-Shimmer"),
                "SwiftyGif",
                .product(name: "SwiftUIIntrospect", package: "SwiftUI-Introspect"),
                "SDWebImageSwiftUI",
                "Kingfisher",
                "AlertToast",
                "SplitView",
                "SwiftUIOverlayContainer",
                "BottomSheet",
                "SFSafeSymbols"
            ],
            path: "Sources/UI"
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
