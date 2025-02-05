// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "UIComponent",
    platforms: [
        .iOS("13.0"),
        .tvOS("15.0"),
    ],
    products: [
        .library(
            name: "UIComponent",
            targets: ["UIComponent"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.0.0"),
        .package(url: "https://github.com/teamlapse/swift-perception", revision: "b5500c32b22ea461cb1a2298f94a6ad6c93a4df2"),
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "UIComponent",
            dependencies: [
                .product(name: "IssueReporting", package: "xctest-dynamic-overlay"),
                .product(name: "Perception", package: "swift-perception"),
                .product(name: "ConcurrencyExtras", package: "swift-concurrency-extras"),
            ]
        ),
        .testTarget(
            name: "UIComponentTests",
            dependencies: ["UIComponent"]
        ),
    ]
)
