// Shared formatter — 1 decimal place, used by all reason strings.
private func f(_ v: Double) -> String { String(format: "%.1f", v) }

// MARK: - Hard guards
// Registered in SwimmingConditions.hardGuards.
// The first non-nil result ends evaluation immediately.

internal struct ThunderstormRule: SwimmingRule {
    func evaluate(_ weather: WeatherResult) -> Verdict? {
        guard weather.weatherCode.isThunderstorm else { return nil }
        return .noGo(reasons: ["Thunderstorm (WMO \(weather.weatherCode.raw))"])
    }
}

// MARK: - Scoring rules
// Registered in SwimmingConditions.scoringRules.
// All rules run; noGo and caution reasons accumulate independently.

internal struct WaterTemperatureRule: SwimmingRule {
    func evaluate(_ weather: WeatherResult) -> Verdict? {
        guard let water = weather.waterTemperature else { return nil }
        switch water.owsSafety {
        case .dangerous:
            return .noGo(reasons: [
                "Water surface temperature \(f(water.inCelsius)) °C (\(f(water.inFahrenheit)) °F) is below the safe minimum of 11°C"
            ])
        case .extremeRisk:
            return .noGo(reasons: [
                "Water surface temperature \(f(water.inCelsius)) °C (\(f(water.inFahrenheit)) °F) — incapacitation risk within minutes"
            ])
        case .coldShock:
            return .caution(reasons: [
                "Water surface temperature \(f(water.inCelsius)) °C (\(f(water.inFahrenheit)) °F) is in the cold shock zone"
            ])
        case .restricted:
            return .caution(reasons: [
                "Water surface temperature \(f(water.inCelsius)) °C (\(f(water.inFahrenheit)) °F) is below World Aquatics competition minimum (16°C)"
            ])
        case .wetsuitAdvised:
            return .caution(reasons: [
                "Water surface advised at \(f(water.inCelsius)) °C (\(f(water.inFahrenheit)) °F)"
            ])
        case .ideal:
            return nil
        }
    }
}

internal struct UVIndexRule: SwimmingRule {
    func evaluate(_ weather: WeatherResult) -> Verdict? {
        let uv = weather.uvIndex
        switch uv.severity {
        case .extreme:
            return .noGo(reasons: [
                "UV index \(f(uv.value)) is extreme — sun exposure risk is severe"
            ])
        case .veryHigh:
            return .caution(reasons: [
                "UV index \(f(uv.value)) is very high — apply high SPF and limit exposure time"
            ])
        case .high:
            return .caution(reasons: [
                "UV index \(f(uv.value)) is high — sun protection required"
            ])
        case .moderate:
            return .caution(reasons: [
                "UV index \(f(uv.value)) is moderate — sun protection recommended"
            ])
        case .low:
            return nil
        }
    }
}

internal struct WindSpeedRule: SwimmingRule {
    func evaluate(_ weather: WeatherResult) -> Verdict? {
        let wind = weather.windSpeed
        switch wind.swimmingSafety {
        case .dangerous:
            return .noGo(reasons: [
                "Wind \(f(wind.inKmh)) km/h (\(f(wind.inMph)) mph, \(f(wind.inKnots)) kn) exceeds Force 6 — Small Craft Advisory threshold"
            ])
        case .concerning:
            return .caution(reasons: [
                "Wind \(f(wind.inKmh)) km/h (\(f(wind.inMph)) mph, \(f(wind.inKnots)) kn) — Force 4–5, organized swims typically canceled"
            ])
        case .moderate:
            return .caution(reasons: [
                "Wind \(f(wind.inKmh)) km/h (\(f(wind.inMph)) mph, \(f(wind.inKnots)) kn) — surface chop may affect sighting"
            ])
        case .calm:
            return nil
        }
    }
}

internal struct WaveHeightRule: SwimmingRule {
    func evaluate(_ weather: WeatherResult) -> Verdict? {
        guard let wave = weather.waveHeight else { return nil }
        switch wave.swimmingSafety {
        case .dangerous:
            return .noGo(reasons: [
                "Wave height \(f(wave.inMetres)) m (\(f(wave.inFeet)) ft) — dangerous swell"
            ])
        case .concerning:
            return .caution(reasons: [
                "Wave height \(f(wave.inMetres)) m (\(f(wave.inFeet)) ft) — rough conditions"
            ])
        case .moderate:
            return .caution(reasons: [
                "Wave height \(f(wave.inMetres)) m (\(f(wave.inFeet)) ft) — surface chop"
            ])
        case .calm:
            return nil
        }
    }
}