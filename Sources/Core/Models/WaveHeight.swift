public struct WaveHeight: Sendable {
    private let metres: Double
    internal init(metres: Double) { self.metres = metres }
    public var inMetres: Double { metres }
    public var inFeet:   Double { metres * 3.28084 }

    public var swimmingSafety: SwimmingSafety {
        switch metres {
        case ..<0.5:  return .calm
        case 0.5..<1: return .moderate
        case 1..<2:   return .concerning
        default:      return .dangerous  // 2 m+
        }
    }
}