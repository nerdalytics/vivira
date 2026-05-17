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
    targets: [
        .target(
            name: "ViviraDesignSystem",
            resources: [.process("Resources/ViviraColors.xcassets")]
        )
    ]
)
