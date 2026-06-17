internal struct OpenMeteoResponse: Decodable {
    let current: Current

    struct Current: Decodable {
        let airTemperature2m: Double
        let uvIndex:          Double
        let windSpeed10m:     Double

        enum CodingKeys: String, CodingKey {
            case airTemperature2m = "temperature_2m"
            case uvIndex          = "uv_index"
            case windSpeed10m     = "wind_speed_10m"
        }
    }

    func toWeatherResult(waterTemperature: WaterTemperature? = nil) -> WeatherResult {
        WeatherResult(
            airTemperature:   AirTemperature(celsius: current.airTemperature2m),
            waterTemperature: waterTemperature,
            uvIndex:          UVIndex(value: current.uvIndex),
            windSpeed:        WindSpeed(kmh: current.windSpeed10m)
        )
    }
}