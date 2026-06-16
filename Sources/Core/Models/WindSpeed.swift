import Foundation

public struct WindSpeed: Sendable {
    private let kmh: Double

    internal init(kmh: Double) {
        self.kmh = kmh
    }

    // MARK: — Unit conversions
    private static let knotsRatio: Double           = 1.852
    private static let milesRatio: Double           = 1.609344
    private static let metersPerSecondRatio: Double = 3.6

    public var inKmh: Double   { kmh }
    public var inKnots: Double { kmh / Self.knotsRatio }
    public var inMph: Double   { kmh / Self.milesRatio }
    public var inMs: Double    { kmh / Self.metersPerSecondRatio }

    // MARK: — Swimming safety
    public var swimmingSafety: SwimmingSafety {
        // Force 6 (39 km/h+): Small Craft Advisory threshold.
        guard kmh < 39.0 else { return .dangerous }

        switch kmh {
        case 0..<15:   return .calm          // Beaufort 0–2: No effect on swimmers.
        case 15..<28:  return .moderate      // Beaufort 3–4: Surface chop developing.
        case 28..<39:  return .concerning    // Beaufort 4–5: Organized swims cancelled.

        // Unreachable due to guard.
        default:       return .dangerous
        }
    }

    public enum SwimmingSafety {
        case calm        //  < 15 km/h: Calm. No meaningful effect on open water swimmers.
        case moderate    // 15–27 km/h: Beaufort 3–4. Surface chop developing, sighting harder.
        case concerning  // 28–38 km/h: Beaufort 4–5. Organised events cancelled at this range.
        case dangerous   //  ≥ 39 km/h: Beaufort 6+. Small Craft Advisory threshold.
    }
}