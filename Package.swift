// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "UIComponent",
    platforms: [
        .iOS("13.0"),
        .tvOS("15.0")
    ],
    products: [
        .library(
            name: "UIComponent",
            targets: ["UIComponent"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-perception", exact: "1.1.7")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "UIComponent",
            dependencies: [
                .product(name: "Perception", package: "swift-perception")
            ]
        ),
        .testTarget(
            name: "UIComponentTests",
            dependencies: ["UIComponent"]
        ),
    ]
)
