import Foundation

public struct AirTemperature: Sendable {
    private let celsius: Double

    internal init(celsius: Double) {
        self.celsius = celsius
    }

    private static let fahrenheitRatio:  Double = 1.8
    private static let fahrenheitOffset: Double = 32
    private static let kelvinOffset:     Double = 273.15

    public var inCelsius:    Double { celsius }
    public var inFahrenheit: Double { (celsius * Self.fahrenheitRatio) + Self.fahrenheitOffset }
    public var inKelvin:     Double { celsius  + Self.kelvinOffset }
}