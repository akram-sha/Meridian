public struct WeatherResult: Sendable {
    public let airTemperature:   AirTemperature
    public let waterTemperature: WaterTemperature?  // nil until marine fetch is added
    public let uvIndex:          UVIndex
    public let windSpeed:        WindSpeed

    internal init(
    airTemperature:   AirTemperature,
    waterTemperature: WaterTemperature? = nil,
    uvIndex:          UVIndex,
    windSpeed:        WindSpeed,
    ) {
        self.airTemperature   = airTemperature
        self.waterTemperature = waterTemperature
        self.uvIndex          = uvIndex
        self.windSpeed        = windSpeed
    }

    public var swimmingConditions: SwimmingConditions? {
        guard let waterTemperature = waterTemperature else { return nil }
        return SwimmingConditions(
            airTemperature:   airTemperature,
            waterTemperature: waterTemperature,
            uvIndex:          uvIndex,
            windSpeed:        windSpeed
        )
    }
}