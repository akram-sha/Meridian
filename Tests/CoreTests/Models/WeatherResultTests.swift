import Foundation
import Testing
@testable import Core

@Suite("WeatherResult")
struct WeatherResultTests {

    private static func sample(fetchedAt: Date) -> WeatherResult {
        WeatherResult(
            airTemperature: AirTemperature(celsius: 22.5),
            uvIndex:        UVIndex(value: 6.8),
            windSpeed:      WindSpeed(kmh: 12.0),
            weatherCode:    WeatherCode(raw: 1),
            fetchedAt:      fetchedAt,
        )
    }

    @Test("fetchedAt survives an encode/decode round-trip (cache boundary)")
    func fetchedAtRoundTrips() throws {
        let fetchedAt = Date(timeIntervalSince1970: 1_000_000)
        let data      = try JSONEncoder().encode(Self.sample(fetchedAt: fetchedAt))
        let decoded   = try JSONDecoder().decode(WeatherResult.self, from: data)

        #expect(decoded.fetchedAt == fetchedAt)
    }

    @Test("A payload without fetchedAt fails to decode — pre-fetchedAt cache entries degrade to a miss")
    func payloadWithoutFetchedAtFailsToDecode() throws {
        let fetchedAt = Date(timeIntervalSince1970: 1_000_000)
        var object    = try #require(
            try JSONSerialization.jsonObject(
                with: JSONEncoder().encode(Self.sample(fetchedAt: fetchedAt))
            ) as? [String: Any]
        )
        object["fetchedAt"] = nil
        let legacyPayload = try JSONSerialization.data(withJSONObject: object)

        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(WeatherResult.self, from: legacyPayload)
        }
    }
}
