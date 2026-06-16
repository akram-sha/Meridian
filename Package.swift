// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "testApp",
    targets: [
        .target(
            name: "Core",
            path: "Sources/Core"
        ),
        .executableTarget(
            name: "App",
            dependencies: ["Core"],
            path: "Sources/App"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Tests/CoreTests"
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["App", "Core"],
            path: "Tests/AppTests"
        ),
    ]
)
