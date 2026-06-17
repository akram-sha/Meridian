import Core
import Foundation

struct WeatherPresenter {
    public func present(_ weather: WeatherResult) -> String {
        let conditions = weather.swimmingConditions
        let verdictLine: String

        switch conditions.verdict {
        case .go:
            verdictLine = "Good to swim"
        case .caution(let reasons):
            verdictLine = "Swim with caution\n"
            + reasons.map { "  • \($0)" }.joined(separator: "\n")
        case .noGo(let reasons):
            verdictLine = "Do not swim\n"
            + reasons.map { "  • \($0)" }.joined(separator: "\n")
        }

        return """
               ── Swimming Conditions ───────────────────
               Air Temp : \(frmt(weather.airTemperature.inCelsius))°C / \(frmt(weather.airTemperature.inFahrenheit))°F
               UV Index : \(frmt(weather.uvIndex.value)) — \(label(for: weather.uvIndex.severity))
               Wind     : \(frmt(weather.windSpeed.inKmh)) km/h / \(frmt(weather.windSpeed.inKnots)) kn
               \(verdictLine)
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