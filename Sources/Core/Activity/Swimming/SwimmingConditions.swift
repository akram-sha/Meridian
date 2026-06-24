public struct SwimmingConditions: ActivityConditions {
    public let activity:         Activity = .swimming
    public let airTemperature:   AirTemperature
    public let waterTemperature: WaterTemperature
    public let waveHeight:       WaveHeight?
    public let uvIndex:          UVIndex
    public let windSpeed:        WindSpeed
    public let weatherCode:      WeatherCode
    public let verdict:          Verdict

    // waterTemperature is passed explicitly because WeatherResult.waterTemperature
    // is optional and SwimmingConditions is only created after the nil guard in
    // WeatherResult.swimmingConditions.
    internal init(weather: WeatherResult, waterTemperature: WaterTemperature) {
        self.airTemperature   = weather.airTemperature
        self.waterTemperature = waterTemperature
        self.waveHeight       = weather.waveHeight
        self.uvIndex          = weather.uvIndex
        self.windSpeed        = weather.windSpeed
        self.weatherCode      = weather.weatherCode
        self.verdict          = SwimmingConditions.evaluate(weather)
    }

    // MARK: - Rule registry.

    // Hard guards run first. The first non-nil result short-circuits everything.
    // else — use this for conditions that override all other factors (thunderstorm, red flag closure, etc.).
    private static let hardGuards: [any SwimmingRule] = [
        ThunderstormRule(),
    ]

    // Scoring rules all run. noGo and caution reasons accumulate separately.
    // To add a new check: write a SwimmingRule conformance and append it here.
    private static let scoringRules: [any SwimmingRule] = [
        WaterTemperatureRule(),
        UVIndexRule(),
        WindSpeedRule(),
        WaveHeightRule(),
    ]

    // MARK: - Aggregator.

    private static func evaluate(_ weather: WeatherResult) -> Verdict {
        for rule in hardGuards {
            if let verdict = rule.evaluate(weather) { return verdict }
        }

        var noGoReasons:    [String] = []
        var cautionReasons: [String] = []

        for rule in scoringRules {
            switch rule.evaluate(weather) {
            case .noGo(let r):    noGoReasons.append(contentsOf: r)
            case .caution(let r): cautionReasons.append(contentsOf: r)
            case .go, .none:      break
            }
        }

        if !noGoReasons.isEmpty    { return .noGo(reasons: noGoReasons) }
        if !cautionReasons.isEmpty { return .caution(reasons: cautionReasons) }
        return .go
    }
}