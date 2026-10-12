// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TasteCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TasteCore", targets: ["TasteCore"]),
    ],
    targets: [
        .target(name: "TasteCore"),
        .testTarget(name: "TasteCoreTests", dependencies: ["TasteCore"]),
    ]
)
