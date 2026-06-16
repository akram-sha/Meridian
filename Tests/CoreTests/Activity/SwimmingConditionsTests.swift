import Testing
@testable import Core

@Suite("SwimmingConditions")
struct SwimmingConditionsTests {

    @Test("Ideal temperature and low UV returns go")
    func idealConditionsReturnsGo() {
        let conditions = SwimmingConditions(
            temperature: Temperature(celsius: 23),
            uvIndex:     UVIndex(value: 1.0),
            windSpeed:   WindSpeed(kmh: 10)
        )
        if case .go = conditions.verdict { } else {
            Issue.record("Expected .go but got \(conditions.verdict)")
        }
    }

    @Test("Dangerous temperature returns noGo")
    func dangerousTemperatureReturnsNoGo() {
        let conditions = SwimmingConditions(
            temperature: Temperature(celsius: 5),
            uvIndex:     UVIndex(value: 1.0),
            windSpeed:   WindSpeed(kmh: 10)
        )
        if case .noGo = conditions.verdict { } else {
            Issue.record("Expected .noGo but got \(conditions.verdict)")
        }
    }

    @Test("Dangerous wind returns noGo")
    func dangerousWindReturnsNoGo() {
        let conditions = SwimmingConditions(
            temperature: Temperature(celsius: 23),
            uvIndex:     UVIndex(value: 1.0),
            windSpeed:   WindSpeed(kmh: 50)
        )
        if case .noGo = conditions.verdict { } else {
            Issue.record("Expected .noGo but got \(conditions.verdict)")
        }
    }

    @Test("Extreme UV returns noGo")
    func extremeUVReturnsNoGo() {
        let conditions = SwimmingConditions(
            temperature: Temperature(celsius: 23),
            uvIndex:     UVIndex(value: 12),
            windSpeed:   WindSpeed(kmh: 10)
        )
        if case .noGo = conditions.verdict { } else {
            Issue.record("Expected .noGo but got \(conditions.verdict)")
        }
    }

    @Test("Wetsuit temperature returns caution")
    func wetsuitTemperatureReturnsCaution() {
        let conditions = SwimmingConditions(
            temperature: Temperature(celsius: 19),
            uvIndex:     UVIndex(value: 1.0),
            windSpeed:   WindSpeed(kmh: 10)
        )
        if case .caution = conditions.verdict { } else {
            Issue.record("Expected .caution but got \(conditions.verdict)")
        }
    }

    @Test("Multiple caution factors accumulate reasons")
    func multipleCautionFactors() {
        let conditions = SwimmingConditions(
            temperature: Temperature(celsius: 19),
            uvIndex:     UVIndex(value: 7.0),
            windSpeed:   WindSpeed(kmh: 20)
        )
        if case .caution(let reasons) = conditions.verdict {
            #expect(reasons.count == 3)
        } else {
            Issue.record("Expected .caution but got \(conditions.verdict)")
        }
    }
}
