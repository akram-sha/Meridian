import Foundation

public struct WindSpeed: Sendable, Codable {
    private let kmh: Double

    internal init(kmh: Double) {
        if let error = validateNonNegative(kmh) {
            preconditionFailure("WindSpeed \(error)")
        }
        self.kmh = kmh
    }

    // MARK: — Unit conversions.
    private static let knotsRatio: Double           = 1.852
    private static let milesRatio: Double           = 1.609344
    private static let metersPerSecondRatio: Double = 3.6

    public var inKmh: Double   { kmh }
    public var inKnots: Double { kmh / Self.knotsRatio }
    public var inMph: Double   { kmh / Self.milesRatio }
    public var inMs: Double    { kmh / Self.metersPerSecondRatio }

    // MARK: — Swimming safety.
    public var swimmingSafety: SwimmingSafety {
        // Force 6 (39 km/h+): Small Craft Advisory threshold.
        guard kmh < 39.0 else { return .dangerous }

        switch kmh {
        case 0..<15:   return .calm          // Beaufort 0–2: No effect on swimmers.
        case 15..<28:  return .moderate      // Beaufort 3–4: Surface chop developing.
        case 28..<39:  return .concerning    // Beaufort 4–5: Organized swims canceled.

        // Unreachable due to guard.
        default:       return .dangerous
        }
    }

    private enum CodingKeys: String, CodingKey { case kmh }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kmh = try container.decode(Double.self, forKey: .kmh)
        if let error = validateNonNegative(kmh) {
            throw DecodingError.dataCorruptedError(forKey: .kmh, in: container, debugDescription: "WindSpeed \(error)")
        }
        self.kmh = kmh
    }
}