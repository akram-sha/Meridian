import Testing
import Foundation
@testable import Core
@testable import App

@Suite("WeatherPresenter")
struct WeatherPresenterTests {

    // Shared fixtures — init() runs before each test, like @BeforeEach
    let presenter: WeatherPresenter
    let defaultWeather: WeatherResult

    init() {
        presenter = WeatherPresenter()
        defaultWeather = WeatherResult(
            temperature: Temperature(celsius: 22.5),
            uvIndex:     UVIndex(value: 6.8),
            windSpeed:   WindSpeed(kmh: 12.0)
        )
    }

    // Uses defaultWeather — no repeated construction
    @Test("Output contains celsius value")
    func containsCelsius() {
        let output = presenter.present(defaultWeather)
        #expect(output.contains("22.5°C"))
    }

    @Test("Output contains UV numeric value")
    func containsUVValue() {
        let output = presenter.present(defaultWeather)
        #expect(output.contains("6.8"))
    }

    // Needs a specific temperature — override just that
    @Test("Output contains fahrenheit conversion")
    func containsFahrenheit() {
        let weather = WeatherResult(
            temperature: Temperature(celsius: 0),
            uvIndex:     UVIndex(value: 1.0),
            windSpeed:   WindSpeed(kmh: 12.0)
        )
        let output = presenter.present(weather)
        #expect(output.contains("32.0°F"))
    }

    // Needs UV 7.0 to hit .high severity
    @Test("Output contains UV severity label")
    func containsSeverityLabel() {
        let weather = WeatherResult(
            temperature: Temperature(celsius: 20),
            uvIndex:     UVIndex(value: 7.0),
            windSpeed:   WindSpeed(kmh: 12.0)
        )
        let output = presenter.present(weather)
        #expect(output.contains("High"))
    }
}