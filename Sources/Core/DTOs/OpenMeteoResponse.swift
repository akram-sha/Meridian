internal struct OpenMeteoResponse: Decodable {
    let current: Current

    struct Current: Decodable {
        let temperature2m: Double
        let uvIndex:       Double
        let windSpeed10m:  Double

        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case uvIndex =       "uv_index"
            case windSpeed10m =  "wind_speed_10m"
        }
    }

    func toWeatherResult() -> WeatherResult {
        WeatherResult(
            temperature: Temperature(celsius: current.temperature2m),
            uvIndex:     UVIndex(value: current.uvIndex),
            windSpeed:   WindSpeed(kmh: current.windSpeed10m)
        )
    }
}