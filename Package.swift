// swift-tools-version:5.8

import PackageDescription

let package = Package(
    name: "UIComponent",
    platforms: [
        .iOS("17.0"),
    ],
    products: [
        .library(
            name: "UIComponent",
            targets: ["UIComponent"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-issue-reporting", from: "1.5.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "UIComponent",
            dependencies: [
                .product(name: "IssueReporting", package: "swift-issue-reporting")
            ]
        ),
        .testTarget(
            name: "UIComponentTests",
            dependencies: ["UIComponent", .product(name: "IssueReportingTestSupport", package: "swift-issue-reporting")]
        ),
    ]
)
