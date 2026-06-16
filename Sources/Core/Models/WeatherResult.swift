public struct WeatherResult: Sendable {
    public let temperature: Temperature
    public let uvIndex:     UVIndex
    public let windSpeed:   WindSpeed

    internal init(temperature: Temperature, uvIndex: UVIndex, windSpeed: WindSpeed) {
        self.temperature = temperature
        self.uvIndex     = uvIndex
        self.windSpeed   = windSpeed
    }

    public var swimmingConditions: SwimmingConditions {
        SwimmingConditions(
            temperature: temperature,
            uvIndex:     uvIndex,
            windSpeed:   windSpeed
        )
    }
}