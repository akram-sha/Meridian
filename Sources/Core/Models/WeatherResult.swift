public struct WeatherResult: Sendable {
    public let airTemperature: AirTemperature
    public let uvIndex:        UVIndex
    public let windSpeed:      WindSpeed

    internal init(airTemperature: AirTemperature, uvIndex: UVIndex, windSpeed: WindSpeed) {
        self.airTemperature = airTemperature
        self.uvIndex        = uvIndex
        self.windSpeed      = windSpeed
    }

    public var swimmingConditions: SwimmingConditions {
        SwimmingConditions(
            airTemperature: airTemperature,
            uvIndex:        uvIndex,
            windSpeed:      windSpeed
        )
    }
}