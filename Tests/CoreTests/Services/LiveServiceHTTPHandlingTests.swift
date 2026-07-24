import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import Core

// Covers the HTTP-handling branches inside the two live network services
// (OpenMeteoService, OpenMarineService) that no other test exercises: both structs
// share the same three-guard shape (non-HTTPURLResponse → invalidResponse, non-200 →
// httpError(statusCode:), otherwise decode). OpenMeteoServiceTests/MarineServiceTests
// test the DTOs directly and test doubles (Stub/Fake) that never call the real
// fetch() at all — this suite is what actually exercises OpenMeteoService.fetch()
// and OpenMarineService.fetch() themselves.
//
// `.serialized`: every test here mutates MockURLProtocol's shared, unsynchronized
// `handler` — see that file's header comment. Do not remove this trait.
@Suite("Live service HTTP handling", .serialized)
struct LiveServiceHTTPHandlingTests {

    // MARK: - OpenMeteoService

    private let validWeatherBody = Data(
        #"{"current":{"temperature_2m":20.0,"uv_index":3.0,"wind_speed_10m":10.0,"weather_code":1}}"#.utf8
    )

    @Test("OpenMeteoService: 200 with a valid body returns a decoded WeatherResult")
    func weatherSuccessPath() async throws {
        MockURLProtocol.handler = { [validWeatherBody] request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, validWeatherBody)
        }
        let service = OpenMeteoService(session: MockURLProtocol.makeSession())
        let result  = try await service.fetch(coordinate: try Coordinate(latitude: 52.37, longitude: 4.53))
        #expect(result.airTemperature.inCelsius == 20.0)
    }

    @Test("OpenMeteoService: outbound URL carries only canonical two-decimal coordinates")
    func weatherURLUsesCanonicalCoordinates() async throws {
        // The privacy guarantee end to end: a Coordinate built from precise input
        // must reach the wire as its rounded canonical form, nothing finer.
        MockURLProtocol.handler = { [validWeatherBody] request in
            let query = request.url?.query ?? ""
            #expect(query.contains("latitude=52.37"))
            #expect(query.contains("longitude=4.53"))
            #expect(!query.contains("52.3717"))
            #expect(!query.contains("4.5333"))
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, validWeatherBody)
        }
        let service = OpenMeteoService(session: MockURLProtocol.makeSession())
        _ = try await service.fetch(coordinate: try Coordinate(latitude: 52.3717, longitude: 4.5333))
    }

    @Test("OpenMeteoService: non-200 status throws httpError with the actual status code")
    func weatherNonOKStatusThrowsHTTPError() async throws {
        MockURLProtocol.handler = { [validWeatherBody] request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 503, httpVersion: nil, headerFields: nil)!
            return (response, validWeatherBody)
        }
        let service = OpenMeteoService(session: MockURLProtocol.makeSession())
        await #expect(throws: OpenMeteoService.ServiceError.httpError(statusCode: 503)) {
            try await service.fetch(coordinate: try Coordinate(latitude: 52.37, longitude: 4.53))
        }
    }

    @Test("OpenMeteoService: a non-HTTP URLResponse throws invalidResponse")
    func weatherNonHTTPResponseThrowsInvalidResponse() async throws {
        MockURLProtocol.handler = { [validWeatherBody] request in
            let response = URLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
            return (response, validWeatherBody)
        }
        let service = OpenMeteoService(session: MockURLProtocol.makeSession())
        await #expect(throws: OpenMeteoService.ServiceError.invalidResponse) {
            try await service.fetch(coordinate: try Coordinate(latitude: 52.37, longitude: 4.53))
        }
    }

    @Test("OpenMeteoService: 200 with a malformed body propagates DecodingError, not a ServiceError")
    func weatherMalformedBodyPropagatesDecodingError() async throws {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("{ not valid json }".utf8))
        }
        let service = OpenMeteoService(session: MockURLProtocol.makeSession())
        await #expect(throws: DecodingError.self) {
            try await service.fetch(coordinate: try Coordinate(latitude: 52.37, longitude: 4.53))
        }
    }

    // MARK: - OpenMarineService

    private let validMarineBody = Data(#"{"current":{"sea_surface_temperature":18.0}}"#.utf8)

    @Test("OpenMarineService: 200 with a valid body returns decoded MarineConditions")
    func marineSuccessPath() async throws {
        MockURLProtocol.handler = { [validMarineBody] request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, validMarineBody)
        }
        let service = OpenMarineService(session: MockURLProtocol.makeSession())
        let result  = try await service.fetch(coordinate: try Coordinate(latitude: 52.37, longitude: 4.53))
        #expect(result.waterTemperature.inCelsius == 18.0)
    }

    @Test("OpenMarineService: non-200 status throws httpError with the actual status code")
    func marineNonOKStatusThrowsHTTPError() async throws {
        MockURLProtocol.handler = { [validMarineBody] request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (response, validMarineBody)
        }
        let service = OpenMarineService(session: MockURLProtocol.makeSession())
        await #expect(throws: OpenMarineService.ServiceError.httpError(statusCode: 500)) {
            try await service.fetch(coordinate: try Coordinate(latitude: 52.37, longitude: 4.53))
        }
    }

    @Test("OpenMarineService: a non-HTTP URLResponse throws invalidResponse")
    func marineNonHTTPResponseThrowsInvalidResponse() async throws {
        MockURLProtocol.handler = { [validMarineBody] request in
            let response = URLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
            return (response, validMarineBody)
        }
        let service = OpenMarineService(session: MockURLProtocol.makeSession())
        await #expect(throws: OpenMarineService.ServiceError.invalidResponse) {
            try await service.fetch(coordinate: try Coordinate(latitude: 52.37, longitude: 4.53))
        }
    }

    @Test("OpenMarineService: 200 with a malformed body propagates DecodingError, not a ServiceError")
    func marineMalformedBodyPropagatesDecodingError() async throws {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data("{ not valid json }".utf8))
        }
        let service = OpenMarineService(session: MockURLProtocol.makeSession())
        await #expect(throws: DecodingError.self) {
            try await service.fetch(coordinate: try Coordinate(latitude: 52.37, longitude: 4.53))
        }
    }
}
