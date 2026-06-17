import Testing
@testable import Core
@testable import App

@Suite("WeatherPresenter")
struct WeatherPresenterTests {

    let presenter = WeatherPresenter()
    let output: String

    init() {
        let weather = WeatherResult(
            airTemperature:   AirTemperature(celsius: 22.5),
            waterTemperature: WaterTemperature(celsius: 20),
            uvIndex:          UVIndex(value: 6.8),
            windSpeed:        WindSpeed(kmh: 12.0)
        )
        output = WeatherPresenter().present(weather)
    }

    @Test("Output contains temperature line")
    func containsTemperatureLine() {
        #expect(output.contains("22.5°C"))
    }

    @Test("Output contains UV index line")
    func containsUVLine() {
        #expect(output.contains("6.8"))
    }

    @Test("Output contains wind speed line")
    func containsWindLine() {
        #expect(output.contains("12.0 km/h") || output.contains("12.0"))
    }

    @Test("Output contains verdict line")
    func containsVerdictLine() {
        let hasVerdict = output.contains("Good to swim")
        || output.contains("Swim with caution")
        || output.contains("Do not swim")
        || output.contains("Water temperature unavailable")
        #expect(hasVerdict)
    }
}