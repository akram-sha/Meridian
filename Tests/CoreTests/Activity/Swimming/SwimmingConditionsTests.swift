import Testing
@testable import Core

@Suite("SwimmingConditions")
struct SwimmingConditionsTests {

    // MARK: - Helpers

    // Routes through WeatherResult.swimmingConditions — the real production path.
    // Force-unwrap is safe: waterTemperature is always supplied here.
    private func conditions(
    airTemperature:   Double      = 18,
    waterTemperature: Double      = 23,
    waveHeight:       WaveHeight? = nil,
    uv:               Double      = 1.0,
    kmh:              Double      = 10,
    weatherCode:      Int         = 1,
    ) -> SwimmingConditions {
        WeatherResult(
            airTemperature:   AirTemperature(celsius: airTemperature),
            waterTemperature: WaterTemperature(celsius: waterTemperature),
            waveHeight:       waveHeight,
            uvIndex:          UVIndex(value: uv),
            windSpeed:        WindSpeed(kmh: kmh),
            weatherCode:      WeatherCode(raw: weatherCode),
        ).swimmingConditions!
    }

    // Fixture for wave-only tests: all non-wave inputs are ideal so only the
    // wave rule can fire. If WaterTemperature.owsSafety thresholds change
    // and 24°C stops being .ideal, bump this value.
    private func makeConditions(waveHeight: WaveHeight?) -> SwimmingConditions {
        WeatherResult(
            airTemperature:   AirTemperature(celsius: 20),
            waterTemperature: WaterTemperature(celsius: 24),
            waveHeight:       waveHeight,
            uvIndex:          UVIndex(value: 0),
            windSpeed:        WindSpeed(kmh: 0),
            weatherCode:      WeatherCode(raw: 1),
        ).swimmingConditions!
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
            airTemperature:   25,
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

    // MARK: - Wave height
    // Formatted reason strings derived from WaveHeightRule (1 d.p.):
    //   2.0 m × 3.28084 = 6.56168 → "6.6 ft"
    //   1.0 m × 3.28084 = 3.28084 → "3.3 ft"
    //   0.5 m × 3.28084 = 1.64042 → "1.6 ft"

    @Test("Dangerous wave height is noGo")
    func dangerousWaveHeightIsNoGo() {
        let conditions = makeConditions(waveHeight: WaveHeight(metres: 2.0))
        guard case .noGo(let reasons) = conditions.verdict else {
            Issue.record("Expected .noGo but got \(conditions.verdict)")
            return
        }
        #expect(reasons.contains("Wave height 2.0 m (6.6 ft) — dangerous swell"))
    }

    @Test("Concerning wave height is caution")
    func concerningWaveHeightIsCaution() {
        let conditions = makeConditions(waveHeight: WaveHeight(metres: 1.0))
        guard case .caution(let reasons) = conditions.verdict else {
            Issue.record("Expected .caution but got \(conditions.verdict)")
            return
        }
        #expect(reasons.contains("Wave height 1.0 m (3.3 ft) — rough conditions"))
    }

    @Test("Moderate wave height is caution")
    func moderateWaveHeightIsCaution() {
        let conditions = makeConditions(waveHeight: WaveHeight(metres: 0.5))
        guard case .caution(let reasons) = conditions.verdict else {
            Issue.record("Expected .caution but got \(conditions.verdict)")
            return
        }
        #expect(reasons.contains("Wave height 0.5 m (1.6 ft) — surface chop"))
    }

    @Test("Calm wave height adds no wave reason")
    func calmWaveHeightAddsNoWaveReason() {
        #expect(isGo(makeConditions(waveHeight: WaveHeight(metres: 0.3)).verdict))
    }

    @Test("Nil wave height adds no wave reason")
    func nilWaveHeightAddsNoWaveReason() {
        #expect(isGo(makeConditions(waveHeight: nil).verdict))
    }
}