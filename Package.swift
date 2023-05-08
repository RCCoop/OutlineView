// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "OutlineView",
    products: [
        .library(
            name: "OutlineView",
            targets: ["OutlineView"]),
    ],
    dependencies: [
        .package(url: "https://github.com/RCCoop/ContextMenuBuilder", .branch("main"))
    ],
    targets: [
        .target(
            name: "OutlineView",
            dependencies: [
                "ContextMenuBuilder"
            ]),
        .testTarget(
            name: "OutlineViewTests",
            dependencies: ["OutlineView"]),
    ]
)
