import Testing
@testable import Core

@Suite("Temperature")
struct TemperatureTests {

    @Test("Celsius returns stored value unchanged")
    func celsiusRoundtrip() {
        let temp = Temperature(celsius: 25.0)
        #expect(temp.inCelsius == 25.0)
    }

    @Test("Freezing point: 0°C = 32°F")
    func freezingPointFahrenheit() {
        let temp = Temperature(celsius: 0)
        #expect(temp.inFahrenheit == 32.0)
    }

    @Test("Boiling point: 100°C = 212°F")
    func boilingPointFahrenheit() {
        let temp = Temperature(celsius: 100)
        #expect(temp.inFahrenheit == 212.0)
    }

    @Test("-40 is the same in Celsius and Fahrenheit")
    func negativeFortyEquality() {
        let temp = Temperature(celsius: -40)
        #expect(temp.inFahrenheit == -40.0)
    }

    @Test("Absolute zero: 0°C = 273.15K")
    func kelvinOffset() {
        let temp = Temperature(celsius: 0)
        #expect(temp.inKelvin == 273.15)
    }

    @Test("Kelvin is always Celsius + 273.15")
    func kelvinConversion() {
        let temp = Temperature(celsius: 100)
        #expect(temp.inKelvin == 373.15)
    }
}