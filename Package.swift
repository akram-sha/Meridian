// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Meridian",
    products: [
        // Declared explicitly so the AWSLambdaPackager `archive` plugin can find it —
        // the plugin only archives executable *products*, not bare targets.
        .executable(name: "MeridianLambda", targets: ["MeridianLambda"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/soto-project/soto.git", from: "7.10.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-runtime.git", from: "2.6.0"),
        .package(url: "https://github.com/swift-server/swift-aws-lambda-events.git", from: "1.0.0"),
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
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/DynamoDBForecastCache"
        ),
        // The Lambda handler's testable core: request parsing, wire-contract response/error
        // shapes, and the query → Core → JSON translation. Deliberately free of API Gateway
        // and AWS types so MeridianLambdaTests needs no Lambda runtime — the same DTO-boundary
        // rule as Core's DTOs/, applied to the API's own wire shape.
        .target(
            name: "MeridianLambdaCore",
            dependencies: [
                "Core",
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/MeridianLambdaCore"
        ),
        // Thin runtime shim (untestable executable, same as App): decodes the API Gateway
        // v1 proxy event, delegates to MeridianLambdaCore, wires DynamoDBForecastCache in.
        .executableTarget(
            name: "MeridianLambda",
            dependencies: [
                "Core",
                "DynamoDBForecastCache",
                "MeridianLambdaCore",
                .product(name: "AWSLambdaRuntime", package: "swift-aws-lambda-runtime"),
                .product(name: "AWSLambdaEvents", package: "swift-aws-lambda-events"),
                .product(name: "SotoDynamoDB", package: "soto"),
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/MeridianLambda"
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
        .testTarget(
            name: "MeridianLambdaTests",
            dependencies: ["MeridianLambdaCore", "Core"],
            path: "Tests/MeridianLambdaTests"
        ),
    ]
)