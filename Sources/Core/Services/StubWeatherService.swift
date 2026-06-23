public struct StubWeatherService: WeatherService, Sendable {
    public init() {}

    public func fetch(latitude: Double, longitude: Double) async throws -> WeatherResult {
        WeatherResult(
            airTemperature:   AirTemperature(celsius: 22.5),
            waterTemperature: WaterTemperature(celsius: 18.0),
            uvIndex:          UVIndex(value: 6.8),
            windSpeed:        WindSpeed(kmh: 12.0),
            weatherCode:      WeatherCode(raw: 1),
        )
    }
}