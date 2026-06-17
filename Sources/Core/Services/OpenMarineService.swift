import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct OpenMarineService: MarineService, Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(latitude: Double, longitude: Double) async throws -> WaterTemperature {
        let url = try buildURL(latitude: latitude, longitude: longitude)
        let (data, response) = try await session.data(from: url)
        let OK = 200

        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }
        guard http.statusCode == OK else {
            throw ServiceError.httpError(statusCode: http.statusCode)
        }

        let decoded = try JSONDecoder().decode(MarineResponse.self, from: data)
        return decoded.toWaterTemperature()
    }

    private func buildURL(latitude: Double, longitude: Double) throws -> URL {
        let privacyLatitude  = (latitude  * 100).rounded() / 100
        let privacyLongitude = (longitude * 100).rounded() / 100
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "marine-api.open-meteo.com"
        components.path   = "/v1/marine"
        components.queryItems = [
            URLQueryItem(name: "latitude",  value: String(privacyLatitude)),
            URLQueryItem(name: "longitude", value: String(privacyLongitude)),
            URLQueryItem(name: "current",   value: "sea_surface_temperature"),
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
        case inlandCoordinate
    }
}