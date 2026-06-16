public struct SwimmingConditions: ActivityConditions {
    public let activity:    Activity = .swimming
    public let temperature: Temperature
    public let uvIndex:     UVIndex
    public let windSpeed:   WindSpeed
    public let verdict:     Verdict

    internal init(temperature: Temperature, uvIndex: UVIndex, windSpeed: WindSpeed) {
        self.temperature = temperature
        self.uvIndex     = uvIndex
        self.windSpeed   = windSpeed
        self.verdict     = SwimmingConditions.evaluate(
            temperature: temperature,
            uvIndex: uvIndex,
            windSpeed: windSpeed
        )
    }

    private static func evaluate(
        temperature: Temperature,
        uvIndex:     UVIndex,
        windSpeed:   WindSpeed,
    ) -> Verdict {
        var noGoReasons: [String]    = []
        var cautionReasons: [String] = []

        // Temperature assessment
        switch temperature.owsSafety {
        case .dangerous:
            noGoReasons.append("Water temperature \(frmt(temperature.inCelsius)) °C (\(frmt(temperature.inFahrenheit)) °F) is below the safe minimum of 11°C")
        case .extremeRisk:
            noGoReasons.append("Water temperature \(frmt(temperature.inCelsius)) °C (\(frmt(temperature.inFahrenheit)) °F) — incapacitation risk within minutes")
        case .coldShock:
            cautionReasons.append("Water temperature \(frmt(temperature.inCelsius)) °C (\(frmt(temperature.inFahrenheit)) °F) is in the cold shock zone")
        case .restricted:
            cautionReasons.append("Water temperature \(frmt(temperature.inCelsius)) °C (\(frmt(temperature.inFahrenheit)) °F) is below World Aquatics competition minimum (16°C)")
        case .wetsuitAdvised:
            cautionReasons.append("Wetsuit advised at \(frmt(temperature.inCelsius)) °C (\(frmt(temperature.inFahrenheit)) °F)")
        case .ideal:
            break
        }

        // UV assessment
        switch uvIndex.severity {
        case .extreme:
            noGoReasons.append("UV index \(frmt(uvIndex.value)) is extreme — sun exposure risk is severe")
        case .veryHigh:
            cautionReasons.append("UV index \(frmt(uvIndex.value)) is very high — apply high SPF and limit exposure time")
        case .high:
            cautionReasons.append("UV index \(frmt(uvIndex.value)) is high — sun protection required")
        case .moderate:
            cautionReasons.append("UV index \(frmt(uvIndex.value)) is moderate — sun protection recommended")
        case .low:
            break
        }

        // Wind speed assessment
        switch windSpeed.swimmingSafety {
        case .dangerous:
            noGoReasons.append("Wind \(frmt(windSpeed.inKmh)) km/h (\(frmt(windSpeed.inMph)) mph, \(frmt(windSpeed.inKnots)) kn) exceeds Force 6 — Small Craft Advisory threshold")
        case .concerning:
            cautionReasons.append("Wind \(frmt(windSpeed.inKmh)) km/h (\(frmt(windSpeed.inMph)) mph, \(frmt(windSpeed.inKnots)) kn) — Force 4–5, organized swims typically canceled")
        case .moderate:
            cautionReasons.append("Wind \(frmt(windSpeed.inKmh)) km/h (\(frmt(windSpeed.inMph)) mph, \(frmt(windSpeed.inKnots)) kn) — surface chop may affect sighting")
        case .calm:
            break
        }

        if !noGoReasons.isEmpty {
            return .noGo(reasons: noGoReasons)
        } else if !cautionReasons.isEmpty {
            return .caution(reasons: cautionReasons)
        } else {
            return .go
        }
    }

    private static func frmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}