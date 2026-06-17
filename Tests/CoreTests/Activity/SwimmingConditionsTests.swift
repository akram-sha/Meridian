import Testing
@testable import Core

@Suite("SwimmingConditions")
struct SwimmingConditionsTests {

    // MARK: - Helpers

    private func conditions(
        celsius: Double = 23,
        uv:      Double = 1.0,
        kmh:     Double = 10
    ) -> SwimmingConditions {
        SwimmingConditions(
            airTemperature: AirTemperature(celsius: celsius),
            uvIndex:        UVIndex(value: uv),
            windSpeed:      WindSpeed(kmh: kmh)
        )
    }

    private func isGo(_ verdict: Verdict) -> Bool {
        if case .go = verdict { return true }

        return false
    }

    private func isCaution(_ verdict: Verdict) -> Bool {
        if case .caution = verdict { return true }

        return false
    }

    private func isNoGo(_ verdict: Verdict) -> Bool {
        if case .noGo = verdict { return true }

        return false
    }

    private func cautionReasons(_ verdict: Verdict) -> [String] {
        if case .caution(let reasons) = verdict { return reasons }

        return []
    }

    // MARK: - noGo guard clauses

    @Test("Dangerous temperature returns noGo")
    func dangerousTemperatureReturnsNoGo() {
        #expect(isNoGo(conditions(celsius: 5).verdict))
    }

    @Test("Dangerous wind returns noGo")
    func dangerousWindReturnsNoGo() {
        #expect(isNoGo(conditions(kmh: 50).verdict))
    }

    @Test("Extreme UV returns noGo")
    func extremeUVReturnsNoGo() {
        #expect(isNoGo(conditions(uv: 12).verdict))
    }

    // MARK: - go

    @Test("Ideal conditions return go")
    func idealConditionsReturnGo() {
        #expect(isGo(conditions().verdict))
    }

    // MARK: - caution

    @Test("Wetsuit temperature returns caution")
    func wetsuitTemperatureReturnsCaution() {
        #expect(isCaution(conditions(celsius: 19).verdict))
    }

    @Test("Multiple caution factors accumulate all reasons")
    func multipleCautionFactorsAccumulateReasons() {
        let verdict = conditions(celsius: 19, uv: 7.0, kmh: 20).verdict
        #expect(isCaution(verdict))
        #expect(cautionReasons(verdict).count == 3)
    }
}