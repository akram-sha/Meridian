import Foundation

/// Shared validation for the small set of physically-grounded constraints every measurement
/// value object enforces (finite, and a domain floor where one is physically meaningful).
/// `internal init` uses `preconditionFailure` on violation — those callers are trusted,
/// in-module code (DTOs, stubs); a violation there is a programming bug, not user input, and
/// should crash loudly in development rather than propagate a nonsensical value into a verdict.
/// `Decodable` conformances instead throw `DecodingError` — that path handles untrusted data
/// (a cache round-trip, eventually a wire payload), where a corrupted value must fail the
/// decode gracefully, not crash the process.
enum PhysicalBoundsError: Error, Equatable, CustomStringConvertible {
    case notFinite(Double)
    case belowMinimum(Double, minimum: Double)

    var description: String {
        switch self {
        case .notFinite(let value):
            return "must be finite, got \(value)"
        case .belowMinimum(let value, let minimum):
            return "must be >= \(minimum), got \(value)"
        }
    }
}

func validatePhysical(_ value: Double, atLeast minimum: Double) -> PhysicalBoundsError? {
    guard value.isFinite else { return .notFinite(value) }
    guard value >= minimum else { return .belowMinimum(value, minimum: minimum) }
    return nil
}

func validateNonNegative(_ value: Double) -> PhysicalBoundsError? {
    validatePhysical(value, atLeast: 0)
}
