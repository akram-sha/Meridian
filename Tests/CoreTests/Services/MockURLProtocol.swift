import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// Intercepts URLSession requests so OpenMeteoService/OpenMarineService's own HTTP-handling
// branches (non-200 status, non-HTTPURLResponse, malformed body) can be exercised directly —
// previously these two structs' guard statements had zero coverage anywhere: existing tests
// only exercised the DTOs (JSONDecoder called directly) and Stub/Fake service doubles that
// bypass OpenMeteoService/OpenMarineService's fetch() entirely.
//
// `handler` is `nonisolated(unsafe)` global mutable state — genuinely unsafe under Swift 6
// concurrency if two tests touched it at once. Safety here is guaranteed structurally, not by
// the type system: every test that sets `handler` lives in LiveServiceHTTPHandlingTests.swift,
// under a single `@Suite(.serialized)`, so only one such test ever runs at a time. Do not add a
// MockURLProtocol-based test anywhere else without also serializing it against this suite.
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> (URLResponse, Data))?

    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
