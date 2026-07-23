// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "testApp",
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/soto-project/soto.git", from: "7.10.0"),
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
        // Not imported by App/CLI — Core stays free of AWS dependencies. This target exists
        // to be imported by the future Lambda handler target, and is exercised directly by
        // DynamoDBForecastCacheTests against a LocalStack container.
        .target(
            name: "DynamoDBForecastCache",
            dependencies: [
                "Core",
                .product(name: "SotoDynamoDB", package: "soto"),
            ],
            path: "Sources/DynamoDBForecastCache"
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
        .testTarget(
            name: "DynamoDBForecastCacheTests",
            dependencies: ["DynamoDBForecastCache", "Core"],
            path: "Tests/DynamoDBForecastCacheTests"
        ),
    ]
)