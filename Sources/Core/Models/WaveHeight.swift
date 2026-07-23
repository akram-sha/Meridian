public struct WaveHeight: Sendable, Codable {
    private let metres: Double

    internal init(metres: Double) {
        if let error = validateNonNegative(metres) {
            preconditionFailure("WaveHeight \(error)")
        }
        self.metres = metres
    }

    private static let feetRatio: Double = 3.28084
    public var inMetres: Double { metres }
    public var inFeet:   Double { metres * Self.feetRatio }

    public var swimmingSafety: SwimmingSafety {
        switch metres {
        case ..<0.5:  return .calm
        case 0.5..<1: return .moderate
        case 1..<2:   return .concerning
        default:      return .dangerous   // 2 m+.
        }
    }

    private enum CodingKeys: String, CodingKey { case metres }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let metres = try container.decode(Double.self, forKey: .metres)
        if let error = validateNonNegative(metres) {
            throw DecodingError.dataCorruptedError(forKey: .metres, in: container, debugDescription: "WaveHeight \(error)")
        }
        self.metres = metres
    }
}