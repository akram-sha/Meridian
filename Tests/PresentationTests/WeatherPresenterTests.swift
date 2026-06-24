import Testing
@testable import Core
@testable import Presentation

@Suite("WeatherPresenter")
struct WeatherPresenterTests {

    let presenter = WeatherPresenter()
    let output: String

    init() {
        let weather = WeatherResult(
            airTemperature:   AirTemperature(celsius: 22.5),
            waterTemperature: WaterTemperature(celsius: 20),
            uvIndex:          UVIndex(value: 6.8),
            windSpeed:        WindSpeed(kmh: 12.0),
            weatherCode:      WeatherCode(raw: 1),
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
        #expect(output.contains("12.0 km/h"))
    }

    @Test("Output contains specific caution verdict for 20°C water")
    func containsCautionVerdict() {
        #expect(output.contains("Swim with caution"))
    }

    @Test("Output contains water temperature line")
    func containsWaterTempLine() {
        #expect(output.contains("20.0°C"))
    }

    @Test("Output contains weather code description")
    func containsWeatherCodeDescription() {
        #expect(output.contains("Partly cloudy"))
    }
}