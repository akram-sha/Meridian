import Core
import Foundation

struct WeatherPresenter {
    public func present(_ weather: WeatherResult) -> String {
        let verdictSection: String

        if let conditions = weather.swimmingConditions {
            switch conditions.verdict {
            case .go:
                verdictSection = "Good to swim"
            case .caution(let reasons):
                verdictSection = "Swim with caution\n"
                + reasons.map { "  • \($0)" }.joined(separator: "\n")
            case .noGo(let reasons):
                verdictSection = "Do not swim\n"
                + reasons.map { "  • \($0)" }.joined(separator: "\n")
            }
        } else {
            verdictSection = "Water temperature unavailable — verdict pending"
        }

        let waterTempLine: String
        if let water = weather.waterTemperature {
            waterTempLine = "Water Temp  : \(frmt(water.inCelsius))°C / \(frmt(water.inFahrenheit))°F"
        } else {
            waterTempLine = "Water Temp  : unavailable"
        }

        return """
               ── Swimming Conditions ───────────────────
               Air Temp    : \(frmt(weather.airTemperature.inCelsius))°C / \(frmt(weather.airTemperature.inFahrenheit))°F
               \(waterTempLine)
               UV Index    : \(frmt(weather.uvIndex.value)) — \(label(for: weather.uvIndex.severity))
               Wind        : \(frmt(weather.windSpeed.inKmh)) km/h / \(frmt(weather.windSpeed.inKnots)) kn
               \(verdictSection)
               ─────────────────────────────────────────
               """
    }

    private func frmt(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func label(for severity: UVIndex.Severity) -> String {
        switch severity {
        case .low:      return "Low"
        case .moderate: return "Moderate"
        case .high:     return "High"
        case .veryHigh: return "Very High"
        case .extreme:  return "Extreme"
        }
    }
}