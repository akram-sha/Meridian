import Core

/// A validated `/v1/forecast` request: raw query parameters translated into Core types.
/// Validation order is part of the observable contract — latitude fully, then longitude,
/// then activity; the first violation wins.
public struct ForecastRequest: Sendable {
    public let coordinate: Coordinate
    public let activity: Activity

    public static func parse(
        queryParameters: [String: String]
    ) throws(ForecastAPIError) -> ForecastRequest {
        let latitude: Double = try coordinateComponent(named: "latitude", in: queryParameters)
        let longitude: Double = try coordinateComponent(named: "longitude", in: queryParameters)

        let coordinate: Coordinate
        do {
            coordinate = try Coordinate(latitude: latitude, longitude: longitude)
        } catch let error as CoordinateError {
            throw ForecastAPIError.coordinateOutOfRange(message: error.description)
        } catch {
            // Coordinate.init(latitude:longitude:) only throws CoordinateError.
            throw ForecastAPIError.coordinateOutOfRange(message: "invalid coordinate")
        }

        switch queryParameters["activity"] {
        case nil, .some(""):
            throw ForecastAPIError.unsupportedActivity(message: "activity is required")
        case .some("swimming"):
            return ForecastRequest(coordinate: coordinate, activity: .swimming)
        case .some(let other):
            throw ForecastAPIError.unsupportedActivity(
                message: "activity must be 'swimming', got '\(other)'")
        }
    }

    /// Validates one coordinate query parameter against the wire contract: plain decimal
    /// notation only, and — the privacy rule — at most 2 decimal places. The precision
    /// check runs on the raw string, before any `Double` conversion: "52.370" and "52.37"
    /// are the same `Double`, so over-precision is only detectable on the wire form.
    private static func coordinateComponent(
        named name: String, in queryParameters: [String: String]
    ) throws(ForecastAPIError) -> Double {
        guard let raw: String = queryParameters[name], !raw.isEmpty else {
            throw ForecastAPIError.coordinateOutOfRange(message: "\(name) is required")
        }

        // Plain decimal notation: optional leading "-", ASCII digits, at most one ".",
        // digits on both sides of it. Anything else ("1e3", ".5", "52.", "+52", "٥٢")
        // is rejected as non-numeric rather than guessed at.
        let unsigned: Substring = raw.hasPrefix("-") ? raw.dropFirst() : raw[...]
        let parts: [Substring] = unsigned.split(separator: ".", omittingEmptySubsequences: false)
        let isPlainDecimal: Bool =
            (1...2).contains(parts.count)
            && !parts.contains(where: \.isEmpty)
            && parts.allSatisfy { part in part.allSatisfy { $0.isASCII && $0.isWholeNumber } }

        guard isPlainDecimal, let value: Double = Double(raw) else {
            throw ForecastAPIError.coordinateOutOfRange(
                message: "\(name) must be a plain decimal number, got '\(raw)'")
        }

        if parts.count == 2, parts[1].count > 2 {
            throw ForecastAPIError.coordinateTooPrecise(
                message: "\(name) must have at most 2 decimal places, got \(raw)")
        }

        return value
    }
}
