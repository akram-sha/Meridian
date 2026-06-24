public struct WeatherCode: Sendable {
    public let raw: Int

    internal init(raw: Int) {
        self.raw = raw
    }

    // WMO code 95–99 = thunderstorm (slight, moderate, with hail).
    public var isThunderstorm: Bool { raw >= 95 }

    public var description: String {
        switch raw {
        case 0:        return "Clear sky"
        case 1...3:    return "Partly cloudy"
        case 45, 48:   return "Fog"
        case 51...55:  return "Drizzle"
        case 61...65:  return "Rain"
        case 80...82:  return "Rain showers"
        case 95...99:  return "Thunderstorm"
        default:       return "Code \(raw)"
        }
    }
}