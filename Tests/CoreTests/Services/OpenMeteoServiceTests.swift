import Testing
import Foundation
@testable import Core

@Suite("OpenMeteoService")
struct OpenMeteoServiceTests {

    // MARK: - JSON decoding (tests OpenMeteoResponse directly)

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
        let result = try decode(airTemp: 22.5, uv: 7.0, wind: 18.0)
        #expect(result.airTemperature.inCelsius == 22.5)
        #expect(result.uvIndex.value == 7.0)
        #expect(result.windSpeed.inKmh == 18.0)
    }

    // MARK: - WeatherService protocol contract

    @Test("FakeWeatherService success returns correct result")
    func fakeServiceSuccess() async throws {
        let service = FakeWeatherService(result: .success(
            WeatherResult(
                airTemperature: AirTemperature(celsius: 22.0),
                uvIndex:        UVIndex(value: 5.0),
                windSpeed:      WindSpeed(kmh: 12.0)
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

    private func decode(airTemp: Double, uv: Double, wind: Double) throws -> WeatherResult {
        let json = """
                   {
                       "current": {
                           "temperature_2m": \(airTemp),
                           "uv_index": \(uv),
                           "wind_speed_10m": \(wind)
                       }
                   }
                   """
        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: Data(json.utf8))
        return response.toWeatherResult()
    }
}

// MARK: - FakeWeatherService

private struct FakeWeatherService: WeatherService {
    let result: Result<WeatherResult, Error>
    func fetch(latitude: Double, longitude: Double) async throws -> WeatherResult {
        try result.get()
    }
}