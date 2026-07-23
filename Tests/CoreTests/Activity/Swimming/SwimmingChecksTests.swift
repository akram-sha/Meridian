import Testing
@testable import Core

// Each SwimmingRule conformance is tested here in isolation — calling `.evaluate(_:)`
// directly on the rule, not through SwimmingConditions/WeatherResult. This is
// deliberately separate from SwimmingConditionsTests: the switch statements in
// SwimmingChecks.swift are their own decision logic, independent of the switch
// statements inside each value object's `owsSafety`/`severity`/`swimmingSafety`
// property. A value-object-level test (e.g. WaterTemperatureTests) proves
// `owsSafety` classifies 12°C as `.coldShock`; it says nothing about whether
// WaterTemperatureRule routes `.coldShock` to the correct Verdict case and
// reason text. Only a rule-level test catches a mis-ordered or mis-typed
// `case` in SwimmingChecks.swift itself (e.g. `.coldShock` and `.restricted`
// accidentally swapped) — every branch below exists to close exactly that gap.
//
// Reason-text assertions use exact string equality, not substring matching, and the
// expected strings are built from the same trusted, independently-tested conversion
// properties (WaterTemperature.inFahrenheit, WindSpeed.inKnots, etc.) rather than
// hand-computed numbers — this keeps the assertions precise (catches a wrong unit
// conversion or a wrong rounding, not just a missing keyword) without duplicating
// arithmetic by hand, which would risk the tests themselves being wrong.

private func f(_ v: Double) -> String { String(format: "%.1f", v) }

private func weather(
    airTemperature:   Double      = 20,
    waterTemperature: Double?     = nil,
    waveHeight:       WaveHeight? = nil,
    uv:               Double      = 0,
    kmh:              Double      = 0,
    weatherCode:      Int         = 1
) -> WeatherResult {
    WeatherResult(
        airTemperature:   AirTemperature(celsius: airTemperature),
        waterTemperature: waterTemperature.map { WaterTemperature(celsius: $0) },
        waveHeight:       waveHeight,
        uvIndex:          UVIndex(value: uv),
        windSpeed:        WindSpeed(kmh: kmh),
        weatherCode:      WeatherCode(raw: weatherCode),
    )
}

private func noGoReasons(_ verdict: Verdict?) -> [String]? {
    if case .noGo(let reasons) = verdict { return reasons }
    return nil
}

private func cautionReasons(_ verdict: Verdict?) -> [String]? {
    if case .caution(let reasons) = verdict { return reasons }
    return nil
}

// MARK: - ThunderstormRule

@Suite("ThunderstormRule")
struct ThunderstormRuleTests {
    let rule = ThunderstormRule()

    @Test("WMO 94 does not trigger the guard")
    func belowThresholdIsNil() {
        #expect(rule.evaluate(weather(weatherCode: 94)) == nil)
    }

    @Test("WMO 95 triggers noGo with the raw code in the reason")
    func atThresholdIsNoGo() {
        let reasons = noGoReasons(rule.evaluate(weather(weatherCode: 95)))
        #expect(reasons == ["Thunderstorm (WMO 95)"])
    }

    @Test("WMO 99 still triggers noGo")
    func upperBoundIsNoGo() {
        #expect(noGoReasons(rule.evaluate(weather(weatherCode: 99))) == ["Thunderstorm (WMO 99)"])
    }
}

// MARK: - WaterTemperatureRule

@Suite("WaterTemperatureRule")
struct WaterTemperatureRuleTests {
    let rule = WaterTemperatureRule()

    @Test("Nil water temperature is nil (no opinion)")
    func nilInputIsNil() {
        #expect(rule.evaluate(weather(waterTemperature: nil)) == nil)
    }

    @Test("Ideal water temperature is nil")
    func idealIsNil() {
        #expect(rule.evaluate(weather(waterTemperature: 22)) == nil)
    }

    @Test("Wetsuit-advised band is caution with correctly formatted °C/°F")
    func wetsuitAdvisedIsCaution() {
        let water = WaterTemperature(celsius: 19)
        let reasons = cautionReasons(rule.evaluate(weather(waterTemperature: 19)))
        #expect(reasons == ["Water surface advised at \(f(water.inCelsius)) °C (\(f(water.inFahrenheit)) °F)"])
    }

    @Test("Restricted band is caution, mentioning World Aquatics")
    func restrictedIsCaution() {
        let water = WaterTemperature(celsius: 17)
        let reasons = cautionReasons(rule.evaluate(weather(waterTemperature: 17)))
        #expect(reasons == [
            "Water surface temperature \(f(water.inCelsius)) °C (\(f(water.inFahrenheit)) °F) is below World Aquatics competition minimum (16°C)"
        ])
    }

    @Test("Cold-shock band is caution, mentioning cold shock")
    func coldShockIsCaution() {
        let water = WaterTemperature(celsius: 14)
        let reasons = cautionReasons(rule.evaluate(weather(waterTemperature: 14)))
        #expect(reasons == [
            "Water surface temperature \(f(water.inCelsius)) °C (\(f(water.inFahrenheit)) °F) is in the cold shock zone"
        ])
    }

    @Test("Extreme-risk band is noGo, mentioning incapacitation")
    func extremeRiskIsNoGo() {
        let water = WaterTemperature(celsius: 11.5)
        let reasons = noGoReasons(rule.evaluate(weather(waterTemperature: 11.5)))
        #expect(reasons == [
            "Water surface temperature \(f(water.inCelsius)) °C (\(f(water.inFahrenheit)) °F) — incapacitation risk within minutes"
        ])
    }

    @Test("Dangerous band is noGo, mentioning the 11°C minimum")
    func dangerousIsNoGo() {
        let water = WaterTemperature(celsius: 5)
        let reasons = noGoReasons(rule.evaluate(weather(waterTemperature: 5)))
        #expect(reasons == [
            "Water surface temperature \(f(water.inCelsius)) °C (\(f(water.inFahrenheit)) °F) is below the safe minimum of 11°C"
        ])
    }
}

// MARK: - UVIndexRule

@Suite("UVIndexRule")
struct UVIndexRuleTests {
    let rule = UVIndexRule()

    @Test("Low UV is nil")
    func lowIsNil() {
        #expect(rule.evaluate(weather(uv: 2.9)) == nil)
    }

    @Test("Moderate UV is caution, recommending protection")
    func moderateIsCaution() {
        let reasons = cautionReasons(rule.evaluate(weather(uv: 4.0)))
        #expect(reasons == ["UV index \(f(4.0)) is moderate — sun protection recommended"])
    }

    @Test("High UV is caution, requiring protection")
    func highIsCaution() {
        let reasons = cautionReasons(rule.evaluate(weather(uv: 7.0)))
        #expect(reasons == ["UV index \(f(7.0)) is high — sun protection required"])
    }

    @Test("Very high UV is caution, mentioning high SPF")
    func veryHighIsCaution() {
        let reasons = cautionReasons(rule.evaluate(weather(uv: 9.0)))
        #expect(reasons == ["UV index \(f(9.0)) is very high — apply high SPF and limit exposure time"])
    }

    @Test("Extreme UV is noGo, mentioning severe risk")
    func extremeIsNoGo() {
        let reasons = noGoReasons(rule.evaluate(weather(uv: 11.0)))
        #expect(reasons == ["UV index \(f(11.0)) is extreme — sun exposure risk is severe"])
    }
}

// MARK: - WindSpeedRule

@Suite("WindSpeedRule")
struct WindSpeedRuleTests {
    let rule = WindSpeedRule()

    private func expectedPrefix(forKmh kmh: Double) -> String {
        let wind = WindSpeed(kmh: kmh)
        return "Wind \(f(wind.inKmh)) km/h (\(f(wind.inMph)) mph, \(f(wind.inKnots)) kn)"
    }

    @Test("Calm wind is nil")
    func calmIsNil() {
        #expect(rule.evaluate(weather(kmh: 14.9)) == nil)
    }

    @Test("Moderate wind is caution, with correctly formatted km/h, mph and knots")
    func moderateIsCaution() {
        let reasons = cautionReasons(rule.evaluate(weather(kmh: 20)))
        #expect(reasons == ["\(expectedPrefix(forKmh: 20)) — surface chop may affect sighting"])
    }

    @Test("Concerning wind is caution, mentioning canceled swims")
    func concerningIsCaution() {
        let reasons = cautionReasons(rule.evaluate(weather(kmh: 30)))
        #expect(reasons == ["\(expectedPrefix(forKmh: 30)) — Force 4–5, organized swims typically canceled"])
    }

    @Test("Dangerous wind is noGo, mentioning Small Craft Advisory")
    func dangerousIsNoGo() {
        let reasons = noGoReasons(rule.evaluate(weather(kmh: 50)))
        #expect(reasons == ["\(expectedPrefix(forKmh: 50)) exceeds Force 6 — Small Craft Advisory threshold"])
    }
}

// MARK: - WaveHeightRule

@Suite("WaveHeightRule")
struct WaveHeightRuleTests {
    let rule = WaveHeightRule()

    private func expectedPrefix(forMetres metres: Double) -> String {
        let wave = WaveHeight(metres: metres)
        return "Wave height \(f(wave.inMetres)) m (\(f(wave.inFeet)) ft)"
    }

    @Test("Nil wave height is nil (no opinion)")
    func nilInputIsNil() {
        #expect(rule.evaluate(weather(waveHeight: nil)) == nil)
    }

    @Test("Calm wave height is nil")
    func calmIsNil() {
        #expect(rule.evaluate(weather(waveHeight: WaveHeight(metres: 0.3))) == nil)
    }

    @Test("Moderate wave height is caution, with correctly formatted metres/feet")
    func moderateIsCaution() {
        let reasons = cautionReasons(rule.evaluate(weather(waveHeight: WaveHeight(metres: 0.7))))
        #expect(reasons == ["\(expectedPrefix(forMetres: 0.7)) — surface chop"])
    }

    @Test("Concerning wave height is caution, mentioning rough conditions")
    func concerningIsCaution() {
        let reasons = cautionReasons(rule.evaluate(weather(waveHeight: WaveHeight(metres: 1.5))))
        #expect(reasons == ["\(expectedPrefix(forMetres: 1.5)) — rough conditions"])
    }

    @Test("Dangerous wave height is noGo, mentioning dangerous swell")
    func dangerousIsNoGo() {
        let reasons = noGoReasons(rule.evaluate(weather(waveHeight: WaveHeight(metres: 2.5))))
        #expect(reasons == ["\(expectedPrefix(forMetres: 2.5)) — dangerous swell"])
    }
}
