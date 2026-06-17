import Testing
@testable import Core

@Suite("AirTemperature")
struct AirTemperatureTests {

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