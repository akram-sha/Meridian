public enum Verdict: Sendable {
    case go                          // All conditions are within safe ranges.
    case caution(reasons: [String])  // Activity is possible but one or more conditions warrant caution.
    case noGo(reasons: [String])     // At least one condition makes activity unsafe.
}