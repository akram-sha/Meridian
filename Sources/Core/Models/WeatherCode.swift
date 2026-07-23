public struct WeatherCode: Sendable, Codable {
    public let raw: Int

    internal init(raw: Int) {
        precondition(raw >= 0, "WeatherCode must not be negative, got \(raw)")
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

    private enum CodingKeys: String, CodingKey { case raw }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decode(Int.self, forKey: .raw)
        guard raw >= 0 else {
            throw DecodingError.dataCorruptedError(forKey: .raw, in: container, debugDescription: "WeatherCode must not be negative, got \(raw)")
        }
        self.raw = raw
    }
}