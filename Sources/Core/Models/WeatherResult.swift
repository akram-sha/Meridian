public struct WeatherResult: Sendable {
    public let airTemperature:   AirTemperature
    public let waterTemperature: WaterTemperature?  // nil for inland coordinates or if marine API is unavailable.
    public let waveHeight:       WaveHeight?        // same here.
    public let uvIndex:          UVIndex
    public let windSpeed:        WindSpeed
    public let weatherCode:      WeatherCode

    internal init(
    airTemperature:   AirTemperature,
    waterTemperature: WaterTemperature? = nil,
    waveHeight:       WaveHeight?       = nil,
    uvIndex:          UVIndex,
    windSpeed:        WindSpeed,
    weatherCode:      WeatherCode,
    ) {
        self.airTemperature   = airTemperature
        self.waterTemperature = waterTemperature
        self.waveHeight       = waveHeight
        self.uvIndex          = uvIndex
        self.windSpeed        = windSpeed
        self.weatherCode      = weatherCode
    }

    public var swimmingConditions: SwimmingConditions? {
        guard let waterTemperature = waterTemperature else { return nil }
        return SwimmingConditions(weather: self, waterTemperature: waterTemperature)
    }
}