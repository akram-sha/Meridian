import Foundation

/// Validated, privacy-rounded coordinate pair — the single place coordinate rounding happens.
/// Values are rounded to two decimal places (~1 km) at construction, so no higher-precision
/// location survives past this boundary: not into a cache key, an outbound API call, or a log line.
///  `-0.0` is normalized to `0.0` so equal coordinates always produce identical canonical strings.
public struct Coordinate: Sendable, Hashable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) throws {
        guard (-90.0...90.0).contains(latitude) else {
            throw CoordinateError.latitudeOutOfRange(latitude)
        }
        guard (-180.0...180.0).contains(longitude) else {
            throw CoordinateError.longitudeOutOfRange(longitude)
        }
        self.latitude = Self.privacyRounded(latitude)
        self.longitude = Self.privacyRounded(longitude)
    }

    /// Fixed two-decimal representation, stable across Swift versions and platforms —
    /// the only form used for cache partition keys and outbound API query values.
    public var canonicalLatitude: String { Self.canonical(latitude) }
    public var canonicalLongitude: String { Self.canonical(longitude) }

    private static func privacyRounded(_ value: Double) -> Double {
        let rounded: Double = (value * 100).rounded() / 100
        return rounded == 0 ? 0 : rounded  // collapse -0.0 into 0.0
    }

    private static func canonical(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

/// Thrown for out-of-range (or non-finite) coordinate input. This is user/request
/// input, not a programming bug, so it throws rather than trapping — a CLI prints it,
/// a future API handler maps it to a 400 response.
public enum CoordinateError: Error, Equatable, CustomStringConvertible, LocalizedError {
    case latitudeOutOfRange(Double)
    case longitudeOutOfRange(Double)

    public var description: String {
        switch self {
        case .latitudeOutOfRange(let value):
            return "latitude must be between -90 and 90, got \(value)"
        case .longitudeOutOfRange(let value):
            return "longitude must be between -180 and 180, got \(value)"
        }
    }

    public var errorDescription: String? { description }
}
