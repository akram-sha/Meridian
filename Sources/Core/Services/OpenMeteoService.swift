import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct OpenMeteoService: WeatherService, Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(latitude: Double, longitude: Double) async throws -> WeatherResult {
        let url = try buildURL(latitude: latitude, longitude: longitude)
        let (data, response) = try await session.data(from: url)
        let OK = 200

        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }
        guard http.statusCode == OK else {
            throw ServiceError.httpError(statusCode: http.statusCode)
        }

        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        return decoded.toWeatherResult()
    }

    private func buildURL(latitude: Double, longitude: Double) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "api.open-meteo.com"
        components.path   = "/v1/forecast"
        components.queryItems = [
            URLQueryItem(name: "latitude",  value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "current",   value: "temperature_2m,uv_index,wind_speed_10m"),
        ]

        guard let url = components.url else {
            throw ServiceError.malformedURL
        }
        return url
    }

    public enum ServiceError: Error {
        case malformedURL
        case invalidResponse
        case httpError(statusCode: Int)
    }
}