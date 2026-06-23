import Testing
@testable import Core

@Suite("SwimmingConditions")
struct SwimmingConditionsTests {

    // MARK: - Helpers

    private func conditions(
        airTemperature:   Double = 18,
        waterTemperature: Double = 23,
        uv:               Double = 1.0,
        kmh:              Double = 10,
        weatherCode:      Int    = 1,
    ) -> SwimmingConditions {
        SwimmingConditions(
            airTemperature:   AirTemperature(celsius: airTemperature),
            waterTemperature: WaterTemperature(celsius: waterTemperature),
            uvIndex:          UVIndex(value: uv),
            windSpeed:        WindSpeed(kmh: kmh),
            weatherCode:      WeatherCode(raw: weatherCode),
        )
    }

    private func isGo(_ verdict: Verdict) -> Bool {
        if case .go = verdict { return true }
        return false
    }

    private func isCaution(_ verdict: Verdict) -> Bool {
        if case .caution = verdict { return true }
        return false
    }

    private func isNoGo(_ verdict: Verdict) -> Bool {
        if case .noGo = verdict { return true }
        return false
    }

    private func cautionReasons(_ verdict: Verdict) -> [String] {
        if case .caution(let reasons) = verdict { return reasons }
        return []
    }

    // MARK: - noGo guard clauses

    @Test("Dangerous temperature returns noGo")
    func dangerousTemperatureReturnsNoGo() {
        #expect(isNoGo(conditions(waterTemperature: 5).verdict))
    }

    @Test("Dangerous wind returns noGo")
    func dangerousWindReturnsNoGo() {
        #expect(isNoGo(conditions(kmh: 50).verdict))
    }

    @Test("Extreme UV returns noGo")
    func extremeUVReturnsNoGo() {
        #expect(isNoGo(conditions(uv: 12).verdict))
    }

    // MARK: - go

    @Test("Ideal conditions return go")
    func idealConditionsReturnGo() {
        #expect(isGo(conditions().verdict))
    }

    // MARK: - caution

    @Test("Wetsuit temperature returns caution")
    func wetsuitTemperatureReturnsCaution() {
        #expect(isCaution(conditions(waterTemperature: 19).verdict))
    }

    @Test("Multiple caution factors accumulate all reasons")
    func multipleCautionFactorsAccumulateReasons() {
        let verdict = conditions(waterTemperature: 19, uv: 7.0, kmh: 20).verdict
        #expect(isCaution(verdict))
        #expect(cautionReasons(verdict).count == 3)
    }

    @Test("swimmingConditions is nil when waterTemperature is absent")
    func swimmingConditionsNilWithoutWaterTemperature() {
        let weather = WeatherResult(
            airTemperature:   AirTemperature(celsius: 22.0),
            waterTemperature: nil,
            uvIndex:          UVIndex(value: 3.0),
            windSpeed:        WindSpeed(kmh: 10.0),
            weatherCode:      WeatherCode(raw: 1),
        )
        #expect(weather.swimmingConditions == nil)
    }

    @Test("Thunderstorm is always noGo regardless of other conditions")
    func thunderstormIsNoGo() {
        let verdict = conditions(
            airTemperature:  25,
            waterTemperature: 24,   // ideal
            uv:               2,    // low
            kmh:              5,    // calm
            weatherCode:      95    // thunderstorm
        ).verdict

        if case .noGo(let reasons) = verdict {
            #expect(reasons.contains { $0.contains("Thunderstorm") })
        } else {
            Issue.record("Expected .noGo but got \(verdict)")
        }
    }
}