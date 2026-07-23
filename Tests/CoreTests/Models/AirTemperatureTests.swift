import Foundation
import Testing
@testable import Core

@Suite("AirTemperature")
struct AirTemperatureTests {

    // MARK: - Decoding validation

    @Test("Decoding a value below absolute zero throws DecodingError")
    func decodeBelowAbsoluteZeroThrows() {
        let data = Data(#"{"celsius":-300.0}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(AirTemperature.self, from: data)
        }
    }

    @Test("A valid value round-trips through encode/decode")
    func validValueRoundTrips() throws {
        let encoded = try JSONEncoder().encode(AirTemperature(celsius: 22.5))
        let decoded = try JSONDecoder().decode(AirTemperature.self, from: encoded)
        #expect(decoded.inCelsius == 22.5)
    }

    @Test("Celsius returns stored value unchanged")
    func celsiusRoundtrip() {
        #expect(AirTemperature(celsius: 20).inCelsius == 20)
    }

    @Test("Freezing point: 0°C = 32°F")
    func freezingPoint() {
        #expect(AirTemperature(celsius: 0).inFahrenheit == 32)
    }

    @Test("Boiling point: 100°C = 212°F")
    func boilingPoint() {
        #expect(AirTemperature(celsius: 100).inFahrenheit == 212)
    }

    @Test("-40 is the same in Celsius and Fahrenheit")
    func negativeForty() {
        #expect(AirTemperature(celsius: -40).inFahrenheit == -40)
    }

    @Test("Absolute zero: 0°C = 273.15K")
    func absoluteZero() {
        #expect(AirTemperature(celsius: 0).inKelvin == 273.15)
    }

    @Test("Kelvin is always Celsius + 273.15")
    func kelvinOffset() {
        #expect(AirTemperature(celsius: 37).inKelvin == 310.15)
    }
}