import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public struct OpenMarineService: MarineService, Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(coordinate: Coordinate) async throws -> MarineConditions {
        let url = try buildURL(coordinate: coordinate)
        let (data, response) = try await session.data(from: url)
        let OK = 200

        guard let http = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }
        guard http.statusCode == OK else {
            throw ServiceError.httpError(statusCode: http.statusCode)
        }

        let decoded = try JSONDecoder().decode(MarineResponse.self, from: data)
        return decoded.toMarineConditions()
    }

    private func buildURL(coordinate: Coordinate) throws -> URL {
        // Coordinate is privacy-rounded at construction; only its canonical
        // two-decimal strings ever leave the process.
        var components = URLComponents()
        components.scheme = "https"
        components.host   = "marine-api.open-meteo.com"
        components.path   = "/v1/marine"
        components.queryItems = [
            URLQueryItem(name: "latitude",  value: coordinate.canonicalLatitude),
            URLQueryItem(name: "longitude", value: coordinate.canonicalLongitude),
            URLQueryItem(name: "current",   value: "sea_surface_temperature,wave_height"),
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