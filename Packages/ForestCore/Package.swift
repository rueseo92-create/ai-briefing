// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ForestCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "ForestCore", targets: ["ForestCore"]),
    ],
    targets: [
        .target(name: "ForestCore"),
        .testTarget(name: "ForestCoreTests", dependencies: ["ForestCore"]),
    ]
)
