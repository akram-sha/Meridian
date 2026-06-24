// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "testApp",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "Core",
            path: "Sources/Core"
        ),
        .target(
            name: "Presentation",
            dependencies: ["Core"],
            path: "Sources/Presentation"
        ),
        .executableTarget(
            name: "App",
            dependencies: [
                "Core",
                "Presentation",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/App"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Tests/CoreTests"
        ),
        .testTarget(
            name: "PresentationTests",
            dependencies: ["Presentation", "Core"],
            path: "Tests/PresentationTests"
        ),
    ]
)