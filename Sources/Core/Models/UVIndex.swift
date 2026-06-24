public struct UVIndex: Sendable {
    private let raw: Double

    internal init(value: Double) {
        self.raw = value
    }

    public var value: Double { raw }

    public var severity: Severity {
        // Hard cutoff – World Health Organization Clear-sky UV Index.
        guard raw < 11 else { return .extreme }

        switch raw {
        case 0..<3:  return .low       // Minimal risk:   Low danger for the average person.
        case 3..<6:  return .moderate  // Moderate risk:  Recommended sun protection.
        case 6..<8:  return .high      // High risk:      Protect exposed skin and limit time outside.
        case 8..<11: return .veryHigh  // Very high risk: Apply strong broad-spectrum protection and limit exposure.

        // Unreachable due to guard, but required by compiler.
        default:     return .extreme   // Extreme risk:   Take all precautions as unprotected skin and eyes can burn in minutes.
        }
    }

    public enum Severity {
        case low, moderate, high, veryHigh, extreme
    }
}