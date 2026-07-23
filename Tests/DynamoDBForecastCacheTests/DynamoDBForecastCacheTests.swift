import Foundation
import SotoDynamoDB
import Testing
@testable import Core
@testable import DynamoDBForecastCache

// Gated behind an env var so `swift test` never requires a running LocalStack container.
// Run against LocalStack with:
//   docker compose -f docker/docker-compose.localstack.yml up -d
//   docker/localstack-init.sh
//   MERIDIAN_LOCALSTACK_TESTS=1 swift test --filter DynamoDBForecastCacheTests
private let localStackTestsEnabled = ProcessInfo.processInfo.environment["MERIDIAN_LOCALSTACK_TESTS"] != nil
private let tableName = "meridian-forecast-cache"

@Suite("DynamoDBForecastCache", .enabled(if: localStackTestsEnabled))
struct DynamoDBForecastCacheTests {

    private static let sampleResult = WeatherResult(
        airTemperature: AirTemperature(celsius: 22.5),
        waterTemperature: WaterTemperature(celsius: 18.0),
        waveHeight: WaveHeight(metres: 0.3),
        uvIndex: UVIndex(value: 6.8),
        windSpeed: WindSpeed(kmh: 12.0),
        weatherCode: WeatherCode(raw: 1),
    )

    // Runs `body` against a fresh client pointed at LocalStack, shutting the client
    // down afterwards regardless of whether `body` throws or a #expect fails.
    private func withClient<T>(_ body: (DynamoDB) async throws -> T) async throws -> T {
        let awsClient = AWSClient(credentialProvider: .static(accessKeyId: "test", secretAccessKey: "test"))
        let dynamoDB = DynamoDB(client: awsClient, region: .useast1, endpoint: "http://localhost:4566")
        do {
            let result = try await body(dynamoDB)
            try await awsClient.shutdown()
            return result
        } catch {
            try? await awsClient.shutdown()
            throw error
        }
    }

    @Test("Miss when the key has never been stored")
    func missOnUnknownKey() async throws {
        try await withClient { dynamoDB in
            let cache = DynamoDBForecastCache(client: dynamoDB, tableName: tableName)
            let key   = ForecastCacheKey(latitude: 12.34, longitude: 56.78)

            #expect(await cache.result(for: key) == nil)
        }
    }

    @Test("Hit after store round-trips the full WeatherResult")
    func hitAfterStoreRoundTrips() async throws {
        try await withClient { dynamoDB in
            let cache = DynamoDBForecastCache(client: dynamoDB, tableName: tableName)
            let key   = ForecastCacheKey(latitude: 52.37, longitude: 4.53)

            await cache.store(Self.sampleResult, for: key)
            let cached = await cache.result(for: key)

            #expect(cached?.airTemperature.inCelsius == 22.5)
            #expect(cached?.waterTemperature?.inCelsius == 18.0)
            #expect(cached?.waveHeight?.inMetres == 0.3)
            #expect(cached?.uvIndex.value == 6.8)
            #expect(cached?.windSpeed.inKmh == 12.0)
            #expect(cached?.weatherCode.raw == 1)
        }
    }

    @Test("Stored item carries a ttl attribute in the future")
    func storedItemCarriesTTL() async throws {
        try await withClient { dynamoDB in
            let cache = DynamoDBForecastCache(client: dynamoDB, tableName: tableName, ttl: 60)
            let key   = ForecastCacheKey(latitude: 1.0, longitude: 2.0)
            await cache.store(Self.sampleResult, for: key)

            let response = try await dynamoDB.getItem(
                key: ["pk": .s("coord#1.0_2.0")],
                tableName: tableName
            )
            guard case .n(let ttlString) = response.item?["ttl"], let ttlValue = Double(ttlString) else {
                Issue.record("Expected numeric ttl attribute on stored item")
                return
            }
            #expect(ttlValue > Date().timeIntervalSince1970)
        }
    }
}
