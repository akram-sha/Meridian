public struct SwimmingConditions: ActivityConditions {
    public let activity:         Activity = .swimming
    public let airTemperature:   AirTemperature
    public let waterTemperature: WaterTemperature
    public let uvIndex:          UVIndex
    public let windSpeed:        WindSpeed
    public let verdict:          Verdict

    internal init(
        airTemperature:   AirTemperature,
        waterTemperature: WaterTemperature,
        uvIndex:          UVIndex,
        windSpeed:        WindSpeed
    ) {
        self.airTemperature   = airTemperature
        self.waterTemperature = waterTemperature
        self.uvIndex          = uvIndex
        self.windSpeed        = windSpeed
        self.verdict          = SwimmingConditions.evaluate(
            airTemperature:   airTemperature,
            waterTemperature: waterTemperature,
            uvIndex:          uvIndex,
            windSpeed:        windSpeed
        )
    }

    private static func evaluate(
        airTemperature: AirTemperature,      // For future SwiftUI display.
        waterTemperature: WaterTemperature,
        uvIndex:     UVIndex,
        windSpeed:   WindSpeed,
    ) -> Verdict {
        var noGoReasons: [String]    = []
        var cautionReasons: [String] = []

        // Temperature assessment
        switch waterTemperature.owsSafety {
        case .dangerous:
            noGoReasons.append("Water surface temperature \(frmt(waterTemperature.inCelsius)) °C (\(frmt(waterTemperature.inFahrenheit)) °F) is below the safe minimum of 11°C")
        case .extremeRisk:
            noGoReasons.append("Water surface temperature \(frmt(waterTemperature.inCelsius)) °C (\(frmt(waterTemperature.inFahrenheit)) °F) — incapacitation risk within minutes")
        case .coldShock:
            cautionReasons.append("Water surface temperature \(frmt(waterTemperature.inCelsius)) °C (\(frmt(waterTemperature.inFahrenheit)) °F) is in the cold shock zone")
        case .restricted:
            cautionReasons.append("Water surface temperature \(frmt(waterTemperature.inCelsius)) °C (\(frmt(waterTemperature.inFahrenheit)) °F) is below World Aquatics competition minimum (16°C)")
        case .wetsuitAdvised:
            cautionReasons.append("Water surface advised at \(frmt(waterTemperature.inCelsius)) °C (\(frmt(waterTemperature.inFahrenheit)) °F)")
        case .ideal:
            break
        }

        // UV Safety Assessment.
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

        // Wind Speed Assessment.
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