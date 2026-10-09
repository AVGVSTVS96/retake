// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MemoKit",
    platforms: [.iOS("27.0"), .macOS("26.0")],
    products: [.library(name: "MemoKit", targets: ["MemoKit"])],
    targets: [
        .target(name: "MemoKit"),
        .testTarget(name: "MemoKitTests", dependencies: ["MemoKit"]),
    ]
)
