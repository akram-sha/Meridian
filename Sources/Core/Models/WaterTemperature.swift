public struct WaterTemperature: Sendable, Codable {
    private let celsius: Double

    internal init(celsius: Double) {
        if let error = validatePhysical(celsius, atLeast: Self.absoluteZero) {
            preconditionFailure("WaterTemperature \(error)")
        }
        self.celsius = celsius
    }

    private static let fahrenheitRatio:  Double = 1.8
    private static let fahrenheitOffset: Double = 32
    private static let kelvinOffset:     Double = 273.15
    private static let absoluteZero:     Double = -273.15

    public var inCelsius:    Double { celsius }
    public var inFahrenheit: Double { (celsius * Self.fahrenheitRatio) + Self.fahrenheitOffset }
    public var inKelvin:     Double { celsius + Self.kelvinOffset }

    private enum CodingKeys: String, CodingKey { case celsius }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let celsius = try container.decode(Double.self, forKey: .celsius)
        if let error = validatePhysical(celsius, atLeast: Self.absoluteZero) {
            throw DecodingError.dataCorruptedError(forKey: .celsius, in: container, debugDescription: "WaterTemperature \(error)")
        }
        self.celsius = celsius
    }

    // MARK: — Open water swimming safety (water temperature thresholds).
    public var owsSafety: OWSSafety {
        guard celsius >= 11.0 else { return .dangerous }

        switch celsius {
        case 22...:   return .ideal
        case 18..<22: return .wetsuitAdvised
        case 16..<18: return .restricted
        case 12..<16: return .coldShock
        case 11..<12: return .extremeRisk
        default:      return .dangerous
        }
    }

    public enum OWSSafety: Equatable {
        case ideal           //  ≥ 22°C — comfortable, no wetsuit needed.
        case wetsuitAdvised  // 18–21°C — wetsuit strongly advised for most swimmers.
        case restricted      // 16–17°C — below World Aquatics competition minimum.
        case coldShock       // 12–15°C — cold shock zone, involuntary gasping, drowning risk.
        case extremeRisk     // 11–11.9°C — near British Triathlon hard cutoff, incapacitation likely.
        case dangerous       //  < 11°C — British Triathlon: no OWS recommended below this.
    }
}