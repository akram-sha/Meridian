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

        let decoded   = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let waterTemp = try? await marineService?.fetch(latitude: latitude, longitude: longitude)
        return decoded.toWeatherResult(waterTemperature: waterTemp)
    }

    private func buildURL(latitude: Double, longitude: Double) throws -> URL {
        // Blur exact location to keep user data private.
        let privacyLatitude  = (latitude  * 100).rounded() / 100
        let privacyLongitude = (longitude * 100).rounded() / 100

        var components    = URLComponents()
        components.scheme = "https"
        components.host   = "api.open-meteo.com"
        components.path   = "/v1/forecast"
        components.queryItems = [
            URLQueryItem(name: "latitude",  value: String(privacyLatitude)),
            URLQueryItem(name: "longitude", value: String(privacyLongitude)),
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