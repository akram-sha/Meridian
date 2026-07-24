public struct WaveHeight: Sendable, Codable {
    private let meters: Double

    internal init(meters: Double) {
        if let error: PhysicalBoundsError = validateNonNegative(meters) {
            preconditionFailure("WaveHeight \(error)")
        }
        self.meters = meters
    }

    private static let feetRatio: Double = 3.28084
    public var inMeters:          Double { meters }
    public var inFeet:            Double { meters * Self.feetRatio }

    public var swimmingSafety: SwimmingSafety {
        switch meters {
        case ..<0.5:  return .calm
        case 0.5..<1: return .moderate
        case 1..<2:   return .concerning
        default:      return .dangerous   // 2 m+.
        }
    }

    private enum CodingKeys: String, CodingKey { case meters }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let meters = try container.decode(Double.self, forKey: .meters)
        if let error: PhysicalBoundsError = validateNonNegative(meters) {
            throw DecodingError.dataCorruptedError(forKey: .meters, in: container, debugDescription: "WaveHeight \(error)")
        }
        self.meters = meters
    }
}