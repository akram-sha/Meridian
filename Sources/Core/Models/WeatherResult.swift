import Foundation

public struct WeatherResult: Sendable, Codable {
    public let airTemperature:   AirTemperature
    public let waterTemperature: WaterTemperature?  // nil for inland coordinates or if marine API is unavailable.
    public let waveHeight:       WaveHeight?        // same here.
    public let uvIndex:          UVIndex
    public let windSpeed:        WindSpeed
    public let weatherCode:      WeatherCode
    public let fetchedAt:        Date               // when the forecast was fetched from the provider — survives
                                                    // cache round-trips so consumers can always tell data age.

    internal init(
    airTemperature:   AirTemperature,
    waterTemperature: WaterTemperature? = nil,
    waveHeight:       WaveHeight?       = nil,
    uvIndex:          UVIndex,
    windSpeed:        WindSpeed,
    weatherCode:      WeatherCode,
    fetchedAt:        Date              = Date(),
    ) {
        self.airTemperature   = airTemperature
        self.waterTemperature = waterTemperature
        self.waveHeight       = waveHeight
        self.uvIndex          = uvIndex
        self.windSpeed        = windSpeed
        self.weatherCode      = weatherCode
        self.fetchedAt        = fetchedAt
    }

    public var swimmingConditions: SwimmingConditions? {
        guard let waterTemperature = waterTemperature else { return nil }
        return SwimmingConditions(weather: self, waterTemperature: waterTemperature)
    }
}
