import Foundation
import Testing
@testable import Core

struct WeatherCodeTests {

    // MARK: – Decoding validation

    @Test("Decoding a negative code throws DecodingError")
    func decodeNegativeThrows() {
        let data = Data(#"{"raw":-1}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(WeatherCode.self, from: data)
        }
    }

    @Test("A valid value round-trips through encode/decode")
    func validValueRoundTrips() throws {
        let encoded = try JSONEncoder().encode(WeatherCode(raw: 61))
        let decoded = try JSONDecoder().decode(WeatherCode.self, from: encoded)
        #expect(decoded.raw == 61)
    }

    // MARK: – isThunderstorm boundary

    @Test("WMO 94 is not a thunderstorm")
    func notThunderstorm() {
        #expect(WeatherCode(raw: 94).isThunderstorm == false)
    }

    @Test("WMO 95 is the start of thunderstorm")
    func thunderstormLowerBound() {
        #expect(WeatherCode(raw: 95).isThunderstorm == true)
    }

    @Test("WMO 99 is a thunderstorm")
    func thunderstormUpperBound() {
        #expect(WeatherCode(raw: 99).isThunderstorm == true)
    }

    // MARK: – description
    // Previously only 2 of the 8 branches below were exercised (clearSky, thunderstorm).
    // Each remaining branch gets its own test, including both ends of every range and
    // both discrete values of the `case 45, 48` fog branch — a comma-separated case is
    // two independent conditions, not one, and a mutation dropping either value (e.g.
    // `case 45` alone) would only be caught by testing both.

    @Test("Clear sky description")
    func clearSky() {
        #expect(WeatherCode(raw: 0).description == "Clear sky")
    }

    @Test(
        "Partly cloudy description, both ends of the range",
        arguments: [1, 3]
    )
    func partlyCloudy(raw: Int) {
        #expect(WeatherCode(raw: raw).description == "Partly cloudy")
    }

    @Test(
        "Fog description, both discrete WMO codes",
        arguments: [45, 48]
    )
    func fog(raw: Int) {
        #expect(WeatherCode(raw: raw).description == "Fog")
    }

    @Test(
        "Drizzle description, both ends of the range",
        arguments: [51, 55]
    )
    func drizzle(raw: Int) {
        #expect(WeatherCode(raw: raw).description == "Drizzle")
    }

    @Test(
        "Rain description, both ends of the range",
        arguments: [61, 65]
    )
    func rain(raw: Int) {
        #expect(WeatherCode(raw: raw).description == "Rain")
    }

    @Test(
        "Rain showers description, both ends of the range",
        arguments: [80, 82]
    )
    func rainShowers(raw: Int) {
        #expect(WeatherCode(raw: raw).description == "Rain showers")
    }

    @Test("Thunderstorm description")
    func thunderstormDescription() {
        #expect(WeatherCode(raw: 95).description == "Thunderstorm")
    }

    @Test("Unknown WMO code falls through to the default branch")
    func unknownCodeFallsThroughToDefault() {
        // Closes a previously-documented, previously-unfixed known gap: the default
        // branch ("Code \(raw)" for values outside every known WMO range) had zero
        // coverage. 100 sits just past the last known range (thunderstorm, 95...99),
        // so it can't accidentally match any of the cases above.
        #expect(WeatherCode(raw: 100).description == "Code 100")
    }
}