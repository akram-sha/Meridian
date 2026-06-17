import Testing
@testable import Core

@Suite("WaterTemperature")
struct WaterTemperatureTests {

    // MARK: - Unit conversions

    @Test("Celsius returns stored value unchanged")
    func celsiusRoundtrip() {
        #expect(WaterTemperature(celsius: 20).inCelsius == 20)
    }

    @Test("Freezing point: 0°C = 32°F")
    func freezingPoint() {
        #expect(WaterTemperature(celsius: 0).inFahrenheit == 32)
    }

    @Test("Boiling point: 100°C = 212°F")
    func boilingPoint() {
        #expect(WaterTemperature(celsius: 100).inFahrenheit == 212)
    }

    @Test("-40 is the same in Celsius and Fahrenheit")
    func negativeForty() {
        #expect(WaterTemperature(celsius: -40).inFahrenheit == -40)
    }

    @Test("Absolute zero: 0°C = 273.15K")
    func absoluteZero() {
        #expect(WaterTemperature(celsius: 0).inKelvin == 273.15)
    }

    @Test("Kelvin is always Celsius + 273.15")
    func kelvinOffset() {
        #expect(WaterTemperature(celsius: 37).inKelvin == 310.15)
    }

    // MARK: - OWSSafety thresholds

    @Test("22°C and above is ideal")
    func idealThreshold() {
        #expect(WaterTemperature(celsius: 22).owsSafety == .ideal)
        #expect(WaterTemperature(celsius: 25).owsSafety == .ideal)
    }

    @Test("18°C is the start of wetsuitAdvised")
    func wetsuitAdvisedLowerBound() {
        #expect(WaterTemperature(celsius: 18).owsSafety == .wetsuitAdvised)
    }

    @Test("21.9°C is still wetsuitAdvised")
    func wetsuitAdvisedUpperBound() {
        #expect(WaterTemperature(celsius: 21.9).owsSafety == .wetsuitAdvised)
    }

    @Test("16°C is the start of restricted")
    func restrictedLowerBound() {
        #expect(WaterTemperature(celsius: 16).owsSafety == .restricted)
    }

    @Test("17.9°C is still restricted")
    func restrictedUpperBound() {
        #expect(WaterTemperature(celsius: 17.9).owsSafety == .restricted)
    }

    @Test("12°C is the start of coldShock")
    func coldShockLowerBound() {
        #expect(WaterTemperature(celsius: 12).owsSafety == .coldShock)
    }

    @Test("15.9°C is still coldShock")
    func coldShockUpperBound() {
        #expect(WaterTemperature(celsius: 15.9).owsSafety == .coldShock)
    }

    @Test("11°C is the start of extremeRisk")
    func extremeRiskLowerBound() {
        #expect(WaterTemperature(celsius: 11).owsSafety == .extremeRisk)
    }

    @Test("11.9°C is still extremeRisk")
    func extremeRiskUpperBound() {
        #expect(WaterTemperature(celsius: 11.9).owsSafety == .extremeRisk)
    }

    @Test("Below 11°C is dangerous")
    func dangerousThreshold() {
        #expect(WaterTemperature(celsius: 10.9).owsSafety == .dangerous)
        #expect(WaterTemperature(celsius: 0).owsSafety == .dangerous)
    }
}