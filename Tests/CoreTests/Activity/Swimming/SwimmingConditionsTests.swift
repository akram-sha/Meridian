import Testing
@testable import Core

// This suite tests SwimmingConditions.evaluate() — the aggregator — not the individual
// rules. Per-rule branch/boundary/reason-text coverage lives in SwimmingChecksTests.swift.
// What belongs here is specific to aggregation: how multiple rule outcomes combine into
// one Verdict, and the two decision points that behavior hinges on:
//   decision 1 ("is the verdict .noGo?")    = OR across all scoring rules' noGo outputs
//   decision 2 ("is the verdict .caution?") = NOT(decision 1) AND OR across caution outputs
// Both are logical-OR decisions over independent boolean-ish conditions (does rule R
// contribute a noGo/caution reason?), even though the source has no literal `||` — so
// MC/DC's independent-effect discipline still applies: for each condition (rule) show a
// pair of tests where flipping only that condition flips the decision, all others held
// at their "false" (clean) baseline.
@Suite("SwimmingConditions")
struct SwimmingConditionsTests {

    // MARK: - Helpers

    // Routes through WeatherResult.swimmingConditions — the real production path.
    // Force-unwrap is safe: waterTemperature is always supplied here.
    private func conditions(
    airTemperature:   Double      = 20,
    waterTemperature: Double      = 22,   // .ideal — clean baseline
    waveHeight:       WaveHeight? = nil,  // clean baseline
    uv:               Double      = 0,    // .low — clean baseline
    kmh:              Double      = 0,    // .calm — clean baseline
    weatherCode:      Int         = 1,    // clean baseline
    ) -> SwimmingConditions {
        WeatherResult(
            airTemperature:   AirTemperature(celsius: airTemperature),
            waterTemperature: WaterTemperature(celsius: waterTemperature),
            waveHeight:       waveHeight,
            uvIndex:          UVIndex(value: uv),
            windSpeed:        WindSpeed(kmh: kmh),
            weatherCode:      WeatherCode(raw: weatherCode),
        ).swimmingConditions!
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

    private func noGoReasons(_ verdict: Verdict) -> [String] {
        if case .noGo(let reasons) = verdict { return reasons }
        return []
    }

    private func cautionReasons(_ verdict: Verdict) -> [String] {
        if case .caution(let reasons) = verdict { return reasons }
        return []
    }

    // MARK: - Baseline

    @Test("All-clean baseline returns go")
    func idealConditionsReturnGo() {
        #expect(isGo(conditions().verdict))
    }

    @Test("swimmingConditions is nil when waterTemperature is absent")
    func swimmingConditionsNilWithoutWaterTemperature() {
        let weather = WeatherResult(
            airTemperature:   AirTemperature(celsius: 22.0),
            waterTemperature: nil,
            uvIndex:          UVIndex(value: 3.0),
            windSpeed:        WindSpeed(kmh: 10.0),
            weatherCode:      WeatherCode(raw: 1),
        )
        #expect(weather.swimmingConditions == nil)
    }

    // MARK: - MC/DC-style independence: each scoring rule independently controls
    // decision 1 (the noGo OR). All others held at the clean baseline, so a mutation
    // that dropped any one rule from `scoringRules`, or broke its noGo branch, would
    // make exactly the corresponding case below fail while the other three still pass.

    @Test(
        "Each scoring rule independently drives the verdict to noGo",
        arguments: [
            (waterTemperature: 5.0,  uv: 0.0, kmh: 0.0,  wave: WaveHeight?.none,                     rule: "water temperature"),
            (waterTemperature: 22.0, uv: 12.0, kmh: 0.0,  wave: WaveHeight?.none,                     rule: "UV index"),
            (waterTemperature: 22.0, uv: 0.0, kmh: 50.0, wave: WaveHeight?.none,                     rule: "wind speed"),
            (waterTemperature: 22.0, uv: 0.0, kmh: 0.0,  wave: WaveHeight?.some(WaveHeight(meters: 2.5)), rule: "wave height"),
        ]
    )
    func eachRuleIndependentlyTriggersNoGo(waterTemperature: Double, uv: Double, kmh: Double, wave: WaveHeight?, rule: String) {
        let verdict = conditions(waterTemperature: waterTemperature, waveHeight: wave, uv: uv, kmh: kmh).verdict
        #expect(isNoGo(verdict), "Expected \(rule) alone to trigger noGo")
    }

    // MARK: - MC/DC-style independence: each scoring rule independently controls
    // decision 2 (the caution OR), given decision 1 is already false.

    @Test(
        "Each scoring rule independently drives the verdict to caution",
        arguments: [
            (waterTemperature: 19.0, uv: 0.0, kmh: 0.0,  wave: WaveHeight?.none,                     rule: "water temperature"),
            (waterTemperature: 22.0, uv: 7.0, kmh: 0.0,  wave: WaveHeight?.none,                     rule: "UV index"),
            (waterTemperature: 22.0, uv: 0.0, kmh: 20.0, wave: WaveHeight?.none,                     rule: "wind speed"),
            (waterTemperature: 22.0, uv: 0.0, kmh: 0.0,  wave: WaveHeight?.some(WaveHeight(meters: 0.7)), rule: "wave height"),
        ]
    )
    func eachRuleIndependentlyTriggersCaution(waterTemperature: Double, uv: Double, kmh: Double, wave: WaveHeight?, rule: String) {
        let verdict = conditions(waterTemperature: waterTemperature, waveHeight: wave, uv: uv, kmh: kmh).verdict
        #expect(isCaution(verdict), "Expected \(rule) alone to trigger caution")
    }

    // MARK: - Accumulation across rules (both directions — noGo was previously untested)

    @Test("Multiple simultaneous noGo reasons accumulate from different rules")
    func multipleNoGoFactorsAccumulateReasons() {
        // Dangerous water temperature + dangerous wind: two independent noGo-triggering
        // rules firing together. Symmetric to the caution-accumulation test below —
        // this exact case had no test before this refactor.
        let verdict = conditions(waterTemperature: 5, kmh: 50).verdict
        #expect(isNoGo(verdict))
        #expect(noGoReasons(verdict).count == 2)
    }

    @Test("Multiple caution factors accumulate all reasons")
    func multipleCautionFactorsAccumulateReasons() {
        let verdict = conditions(waterTemperature: 19, uv: 7.0, kmh: 20).verdict
        #expect(isCaution(verdict))
        #expect(cautionReasons(verdict).count == 3)
    }

    // MARK: - noGo takes priority over caution

    @Test("noGo takes priority: a simultaneous caution condition is dropped, not merged")
    func noGoTakesPriorityOverCaution() {
        // Water temperature is dangerous (noGo) AND UV is high (caution) at once.
        // evaluate() only returns noGoReasons in this case — cautionReasons is computed
        // but discarded. Before this refactor, nothing verified that: a bug that
        // accidentally merged both reason lists together would have passed every
        // other test in this file.
        let verdict = conditions(waterTemperature: 5, uv: 7.0).verdict
        guard case .noGo(let reasons) = verdict else {
            Issue.record("Expected .noGo but got \(verdict)")
            return
        }
        #expect(reasons.count == 1)
        #expect(!reasons.contains { $0.contains("UV") })
    }

    // MARK: - Hard guard short-circuit (genuine proof, not incidental overlap)

    @Test("Thunderstorm is always noGo regardless of other conditions")
    func thunderstormIsNoGo() {
        let verdict = conditions(
            airTemperature:   25,
            waterTemperature: 24,   // ideal
            uv:               2,    // low
            kmh:              5,    // calm
            weatherCode:      95    // thunderstorm
        ).verdict

        if case .noGo(let reasons) = verdict {
            #expect(reasons.contains { $0.contains("Thunderstorm") })
        } else {
            Issue.record("Expected .noGo but got \(verdict)")
        }
    }

    @Test("Thunderstorm short-circuits scoring rules entirely — their reasons never run")
    func thunderstormShortCircuitsScoringRules() {
        // Water temperature and wind are BOTH independently noGo-triggering here, on top
        // of the thunderstorm hard guard. The old test only asserted the thunderstorm
        // reason was present, which would still pass even if scoring rules had also run
        // and appended their own reasons — it never proved the "first non-nil result
        // ends evaluation immediately" short-circuit claimed in SwimmingConditions.swift's
        // own comment. Asserting reasons.count == 1 is what actually pins that behavior:
        // if a future change made hard guards run alongside scoring rules instead of
        // instead of them, this test (and only this one) would fail.
        let verdict = conditions(
            waterTemperature: 5,    // would independently be noGo
            kmh:              50,   // would independently be noGo
            weatherCode:      95    // thunderstorm — should be the ONLY reason
        ).verdict

        guard case .noGo(let reasons) = verdict else {
            Issue.record("Expected .noGo but got \(verdict)")
            return
        }
        #expect(reasons == ["Thunderstorm (WMO 95)"])
    }

    // MARK: - Wave height (nil is a distinct input, not just "another calm value")

    @Test("Nil wave height adds no wave reason")
    func nilWaveHeightAddsNoWaveReason() {
        #expect(isGo(conditions(waveHeight: nil).verdict))
    }
}
