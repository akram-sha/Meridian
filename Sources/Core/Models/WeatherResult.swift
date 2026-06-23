public struct WeatherResult: Sendable {
    public let airTemperature:   AirTemperature
    public let waterTemperature: WaterTemperature?  // nil for inland coordinates or if marine API is unavailable
    public let uvIndex:          UVIndex
    public let windSpeed:        WindSpeed
    public let weatherCode:      WeatherCode

    internal init(
        airTemperature:   AirTemperature,
        waterTemperature: WaterTemperature? = nil,
        uvIndex:          UVIndex,
        windSpeed:        WindSpeed,
        weatherCode:      WeatherCode,
    ) {
        self.airTemperature   = airTemperature
        self.waterTemperature = waterTemperature
        self.uvIndex          = uvIndex
        self.windSpeed        = windSpeed
        self.weatherCode      = weatherCode
    }

    public var swimmingConditions: SwimmingConditions? {
        guard let waterTemperature = waterTemperature else { return nil }
        return SwimmingConditions(
            airTemperature:   airTemperature,
            waterTemperature: waterTemperature,
            uvIndex:          uvIndex,
            windSpeed:        windSpeed,
            weatherCode:      weatherCode,
        )
    }
}