import Testing
import Foundation
@testable import Core

@Suite("OpenMeteoService")
struct OpenMeteoServiceTests {

    // MARK: - JSON decoding

    @Test("Valid JSON decodes temperature correctly")
    func decodesTemperature() throws {
        let result = try decode(airTemp: 18.5, uv: 3.0, wind: 10.0)
        #expect(result.airTemperature.inCelsius == 18.5)
    }

    @Test("Valid JSON decodes UV index correctly")
    func decodesUVIndex() throws {
        let result = try decode(airTemp: 20.0, uv: 6.0, wind: 10.0)
        #expect(result.uvIndex.value == 6.0)
    }

    @Test("Valid JSON decodes wind speed correctly")
    func decodesWindSpeed() throws {
        let result = try decode(airTemp: 20.0, uv: 3.0, wind: 25.0)
        #expect(result.windSpeed.inKmh == 25.0)
    }

    @Test("Valid JSON decodes weather code correctly")
    func decodesWeatherCode() throws {
        let result = try decode(airTemp: 20.0, uv: 3.0, wind: 10.0, weatherCode: 95)
        #expect(result.weatherCode.raw            == 95)
        #expect(result.weatherCode.isThunderstorm == true)
    }

    @Test("Malformed JSON throws DecodingError")
    func malformedJSONThrows() throws {
        let data = Data("{ not valid json }".utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        }
    }

    @Test("Missing fields throw DecodingError")
    func missingFieldsThrow() throws {
        let data = Data(#"{"current":{"temperature_2m":20.0}}"#.utf8)
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        }
    }

    @Test("toWeatherResult maps all fields correctly")
    func toWeatherResultMapsAllFields() throws {
        let result = try decode(airTemp: 22.5, uv: 7.0, wind: 18.0, weatherCode: 3)
        #expect(result.airTemperature.inCelsius == 22.5)
        #expect(result.uvIndex.value            == 7.0)
        #expect(result.windSpeed.inKmh          == 18.0)
        #expect(result.weatherCode.raw          == 3)
    }

    // MARK: - WeatherService protocol contract

    @Test("FakeWeatherService success returns correct result")
    func fakeServiceSuccess() async throws {
        let service = FakeWeatherService(result: .success(
            WeatherResult(
                airTemperature: AirTemperature(celsius: 22.0),
                uvIndex:        UVIndex(value: 5.0),
                windSpeed:      WindSpeed(kmh: 12.0),
                weatherCode:    WeatherCode(raw: 1)
            )
        ))
        let result = try await service.fetch(latitude: 0, longitude: 0)
        #expect(result.airTemperature.inCelsius == 22.0)
    }

    @Test("FakeWeatherService failure throws correct error")
    func fakeServiceFailure() async throws {
        let service = FakeWeatherService(result: .failure(OpenMeteoService.ServiceError.invalidResponse))
        await #expect(throws: OpenMeteoService.ServiceError.invalidResponse) {
            try await service.fetch(latitude: 0, longitude: 0)
        }
    }

    // MARK: - Helpers

    private func decode(
        airTemp: Double,
        uv: Double,
        wind: Double,
        weatherCode: Int = 1
    ) throws -> WeatherResult {
        let json = """
                   {
                       "current": {
                           "temperature_2m": \(airTemp),
                           "uv_index": \(uv),
                           "wind_speed_10m": \(wind),
                           "weather_code": \(weatherCode)
                       }
                   }
                   """
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: Data(json.utf8))
        return response.toWeatherResult()
    }

    @Test("toWeatherResult passes through waterTemperature when provided")
    func toWeatherResultPassesThroughWaterTemperature() throws {
        let json = """
                   {
                       "current": {
                           "temperature_2m": 20.0,
                           "uv_index": 3.0,
                           "wind_speed_10m": 10.0,
                           "weather_code": 1
                       }
                   }
                   """.data(using: .utf8)!
        let decoded   = try JSONDecoder().decode(OpenMeteoResponse.self, from: json)
        let waterTemp = WaterTemperature(celsius: 18.0)
        let result    = decoded.toWeatherResult(waterTemperature: waterTemp)
        #expect(result.waterTemperature?.inCelsius == 18.0)
    }

    @Test("toWeatherResult waterTemperature is nil when not provided")
    func toWeatherResultWaterTemperatureDefaultsToNil() throws {
        let json = """
                   {
                       "current": {
                           "temperature_2m": 20.0,
                           "uv_index": 3.0,
                           "wind_speed_10m": 10.0,
                           "weather_code": 1
                       }
                   }
                   """.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: json)
        let result  = decoded.toWeatherResult()
        #expect(result.waterTemperature == nil)
    }
}

// MARK: - FakeWeatherService

private struct FakeWeatherService: WeatherService {
    let result: Result<WeatherResult, Error>
    func fetch(latitude: Double, longitude: Double) async throws -> WeatherResult {
        try result.get()
    }
}