// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.
import PackageDescription

let package = Package(
    name: "MagicPie",
    platforms: [
        .iOS(.v8)
    ],
    products: [
        .library(
            name: "MagicPie",
            targets: ["MagicPie"]),
        .library(
            name: "MagicPieDynamic",
            type: .dynamic,
            targets: ["MagicPie"])
    ],
    targets: [
        .target(
            name: "MagicPie",
            path: "MagicPieLayer",
            resources: [.copy("PrivacyInfo.xcprivacy")],
            publicHeadersPath: "."
        )
    ]
)
