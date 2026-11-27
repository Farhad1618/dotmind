// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DotMind",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v10),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "DotMind", targets: ["DotMind"]),
        .library(name: "DotMindCore", targets: ["DotMindCore"]),
    ],
    targets: [
        .target(
            name: "DotMindCore",
            path: "packages/swift/Sources/DotMindCore"
        ),
        .target(
            name: "DotMind",
            dependencies: ["DotMindCore"],
            path: "packages/swift/Sources/DotMind"
        ),
        .testTarget(
            name: "DotMindTests",
            dependencies: ["DotMindCore"],
            path: "packages/swift/Tests/DotMindTests"
        ),
    ]
)
