import Foundation

public struct AirTemperature: Sendable, Codable {
    private let celsius: Double

    internal init(celsius: Double) {
        if let error: PhysicalBoundsError = validatePhysical(celsius, atLeast: Self.absoluteZero) {
            preconditionFailure("AirTemperature \(error)")
        }
        self.celsius = celsius
    }

    private static let fahrenheitRatio:  Double = 1.8
    private static let fahrenheitOffset: Double = 32
    private static let kelvinOffset:     Double = 273.15
    private static let absoluteZero:     Double = -273.15

    public var inCelsius:    Double { celsius }
    public var inFahrenheit: Double { (celsius * Self.fahrenheitRatio) + Self.fahrenheitOffset }
    public var inKelvin:     Double { celsius  + Self.kelvinOffset }

    private enum CodingKeys: String, CodingKey { case celsius }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let celsius = try container.decode(Double.self, forKey: .celsius)
        if let error = validatePhysical(celsius, atLeast: Self.absoluteZero) {
            throw DecodingError.dataCorruptedError(forKey: .celsius, in: container, debugDescription: "AirTemperature \(error)")
        }
        self.celsius = celsius
    }
}