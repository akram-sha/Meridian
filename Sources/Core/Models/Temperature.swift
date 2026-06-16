import Foundation

public struct Temperature: Sendable {
    private let celsius: Double

    internal init(celsius: Double) {
        self.celsius = celsius
    }

    // MARK: — Unit conversions.
    private static let fahrenheitRatio: Double  = 1.8
    private static let fahrenheitOffset: Double = 32
    private static let kelvinOffset: Double     = 273.15

    public var inCelsius: Double    { celsius }
    public var inFahrenheit: Double { (celsius * Self.fahrenheitRatio) + Self.fahrenheitOffset }
    public var inKelvin: Double     { celsius  + Self.kelvinOffset }

    // MARK: — Open water swimming safety.
    public var owsSafety: OWSSafety {
        // Hard cutoff — British Triathlon: no OWS below 11°C.
        guard celsius >= 11.0 else { return .dangerous }

        switch celsius {
        case 22...:    return .ideal           // no wetsuit needed.
        case 18..<22:  return .wetsuitAdvised  // wetsuit strongly recommended.
        case 16..<18:  return .restricted      // below World Aquatics 16°C competition minimum.
        case 12..<16:  return .coldShock       // cold shock response zone, highest drowning risk.
        case 11..<12:  return .extremeRisk     // near hard cutoff, incapacitation likely.

        // Unreachable due to guard, but required by compiler.
        default:       return .dangerous
        }
    }

    public enum OWSSafety {
        case ideal           //  ≥ 22 °C:  Comfortable, no wetsuit needed.
        case wetsuitAdvised  // 18–21 °C:  Wetsuit strongly advised for most swimmers.
        case restricted      // 16–17 °C:  Below World Aquatics open water competition minimum.
        case coldShock       // 12–15 °C:  Peak cold shock zone — involuntary gasping, swimming failure risk.
        case extremeRisk     // 11–11 °C:  Near British Triathlon hard cutoff. Incapacitation likely within minutes.
        case dangerous       //  < 11 °C:  British Triathlon recommends no open water swimming below this.
    }
}