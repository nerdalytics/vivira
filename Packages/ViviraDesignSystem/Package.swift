// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ViviraDesignSystem",
    platforms: [
        .iOS("26.5"),
        .macOS(.v15)
    ],
    products: [
        .library(name: "ViviraDesignSystem", targets: ["ViviraDesignSystem"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.17.0")
    ],
    targets: [
        .target(
            name: "ViviraDesignSystem",
            resources: [.process("Resources/ViviraColors.xcassets")]
        ),
        .testTarget(
            name: "ViviraDesignSystemTests",
            dependencies: [
                "ViviraDesignSystem",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        )
    ]
)
