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

    // MARK: - Verdict branches
    // `present()` has four independent decision points: the swimmingConditions nil
    // check (2 outcomes), the verdict switch inside it (3 outcomes: go/caution/noGo),
    // the waterTemperature nil check, and the waveHeight nil check. The `init()`
    // fixture above only ever exercises "present + caution" — every other outcome
    // was previously untested, including the exact "verdict pending" text that
    // README.md documents as real, user-visible behavior for inland coordinates.

    @Test("Nil swimmingConditions produces the verdict-pending message, not a verdict switch case")
    func nilSwimmingConditionsShowsPending() {
        let weather = WeatherResult(
            airTemperature:   AirTemperature(celsius: 22.5),
            waterTemperature: nil,
            uvIndex:          UVIndex(value: 6.8),
            windSpeed:        WindSpeed(kmh: 12.0),
            weatherCode:      WeatherCode(raw: 1),
        )
        let output = WeatherPresenter().present(weather)
        #expect(output.contains("Water temperature unavailable — verdict pending"))
        #expect(output.contains("Water Temp   : unavailable"))
    }

    @Test("Go verdict prints \"Good to swim\"")
    func goVerdictText() {
        let weather = WeatherResult(
            airTemperature:   AirTemperature(celsius: 22.5),
            waterTemperature: WaterTemperature(celsius: 22),  // ideal
            uvIndex:          UVIndex(value: 0),               // low
            windSpeed:        WindSpeed(kmh: 0),                // calm
            weatherCode:      WeatherCode(raw: 1),
        )
        let output = WeatherPresenter().present(weather)
        #expect(output.contains("Good to swim"))
    }

    @Test("NoGo verdict prints \"Do not swim\" and its reasons")
    func noGoVerdictText() {
        let weather = WeatherResult(
            airTemperature:   AirTemperature(celsius: 22.5),
            waterTemperature: WaterTemperature(celsius: 5),   // dangerous
            uvIndex:          UVIndex(value: 0),
            windSpeed:        WindSpeed(kmh: 0),
            weatherCode:      WeatherCode(raw: 1),
        )
        let output = WeatherPresenter().present(weather)
        #expect(output.contains("Do not swim"))
        #expect(output.contains("below the safe minimum of 11°C"))
    }

    @Test("Wave height present renders the wave line instead of \"unavailable\"")
    func waveHeightPresentLine() {
        let weather = WeatherResult(
            airTemperature:   AirTemperature(celsius: 22.5),
            waterTemperature: WaterTemperature(celsius: 20),
            waveHeight:       WaveHeight(meters: 0.8),
            uvIndex:          UVIndex(value: 6.8),
            windSpeed:        WindSpeed(kmh: 12.0),
            weatherCode:      WeatherCode(raw: 1),
        )
        let output = WeatherPresenter().present(weather)
        #expect(output.contains("Wave         : 0.8 m / 2.6 ft"))
        #expect(!output.contains("Wave         : unavailable"))
    }

    @Test("Wave height absent renders \"unavailable\"")
    func waveHeightAbsentLine() {
        #expect(output.contains("Wave         : unavailable"))
    }

    // MARK: - UV severity label switch
    // label(for:) has 5 branches; the shared fixture (UV 6.8, .high) only ever
    // exercised one. Each other label gets its own minimal fixture here.

    @Test(
        "Each UV severity maps to its correct label",
        arguments: [
            (uv: 1.0,  label: "Low"),
            (uv: 4.0,  label: "Moderate"),
            (uv: 6.8,  label: "High"),
            (uv: 9.0,  label: "Very High"),
            (uv: 11.0, label: "Extreme"),
        ]
    )
    func uvSeverityLabels(uv: Double, label: String) {
        let weather = WeatherResult(
            airTemperature:   AirTemperature(celsius: 22.5),
            waterTemperature: WaterTemperature(celsius: 20),
            uvIndex:          UVIndex(value: uv),
            windSpeed:        WindSpeed(kmh: 12.0),
            weatherCode:      WeatherCode(raw: 1),
        )
        let output = WeatherPresenter().present(weather)
        #expect(output.contains("— \(label)"))
    }
}