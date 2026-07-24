import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct OpenMeteoService: WeatherService, Sendable {
    private let session:        URLSession
    private let marineService: (any MarineService)?

    public init(session: URLSession = .shared, marineService: (any MarineService)? = nil) {
        self.session       = session
        self.marineService = marineService
    }

    public func fetch(coordinate: Coordinate) async throws -> WeatherResult {
        let url = try buildURL(coordinate: coordinate)
        let (data, response) = try await session.data(from: url)
        let OK = 200

        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }
        guard http.statusCode == OK else {
            throw ServiceError.httpError(statusCode: http.statusCode)
        }

        let decoded: OpenMeteoResponse          = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let marineConditions: MarineConditions? = try? await marineService?.fetch(coordinate: coordinate)
        return decoded.toWeatherResult(
            waterTemperature: marineConditions?.waterTemperature,
            waveHeight:       marineConditions?.waveHeight,
        )
    }

    private func buildURL(coordinate: Coordinate) throws -> URL {
        // Coordinate is privacy-rounded at construction; only its canonical
        // two-decimal strings ever leave the process.
        var components: URLComponents = URLComponents()
        components.scheme     = "https"
        components.host       = "api.open-meteo.com"
        components.path       = "/v1/forecast"
        components.queryItems = [
            URLQueryItem(name: "latitude",  value: coordinate.canonicalLatitude),
            URLQueryItem(name: "longitude", value: coordinate.canonicalLongitude),
            URLQueryItem(name: "current",   value: "temperature_2m,uv_index,wind_speed_10m,weather_code"),
        ]

        guard let url = components.url else {
            throw ServiceError.malformedURL
        }
        return url
    }

    public enum ServiceError: Error, Equatable {
        case malformedURL
        case invalidResponse
        case httpError(statusCode: Int)
    }
}