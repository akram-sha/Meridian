import Testing
@testable import Core

struct WeatherCodeTests {

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

    @Test("Clear sky description")
    func clearSky() {
        #expect(WeatherCode(raw: 0).description == "Clear sky")
    }

    @Test("Thunderstorm description")
    func thunderstormDescription() {
        #expect(WeatherCode(raw: 95).description == "Thunderstorm")
    }
}