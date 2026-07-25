import Core
import Foundation
import Logging

/// Transport-neutral response — what the runtime shim turns into an API Gateway response.
/// Keeping this (and everything else in this module) free of AWSLambdaEvents types is what
/// lets the whole handler pipeline be unit-tested without a Lambda runtime.
public struct APIResponse: Sendable, Equatable {
    public let statusCode: Int
    public let body:       String
}

/// `GET /v1/forecast` minus the transport: query parameters in, contract JSON out.
/// A thin adapter over Core — no verdict logic, no formatting beyond the wire shape,
/// same invariant as `App` and the future iOS target.
public struct ForecastAPI: Sendable {
    private let coordinator: ForecastCoordinator
    private let logger: Logger

    public init(
        coordinator: ForecastCoordinator,
        logger: Logger = Logger(label: "meridian.forecast-api")
    ) {
        self.coordinator = coordinator
        self.logger = logger
    }

    public func handle(queryParameters: [String: String], requestID: String) async -> APIResponse {
        let request: ForecastRequest
        do {
            request = try ForecastRequest.parse(queryParameters: queryParameters)
        } catch {
            // Log the stable code only — a rejected request's raw parameters may hold a
            // too-precise coordinate, which must never reach a log line from here.
            logger.info("Rejected forecast request", metadata: [
                "requestID": .string(requestID),
                "code":      .string(error.code),
            ])
            return Self.response(for: error)
        }

        // Rounded canonical coordinates are the only location data allowed in names,
        // cache keys, or log lines (see Coordinate).
        let canonical: String =
            "\(request.coordinate.canonicalLatitude),\(request.coordinate.canonicalLongitude)"
        let location: Location = Location(name: canonical, coordinate: request.coordinate)

        let forecast: LocationForecast
        do {
            forecast = try await coordinator.forecast(for: location)
        } catch {
            logger.warning("Upstream forecast fetch failed", metadata: [
                "requestID":  .string(requestID),
                "coordinate": .string(canonical),
                "error":      .string(String(describing: error)),
            ])
            return Self.response(
                for: .upstreamUnavailable(message: "forecast provider request failed"))
        }

        logger.info("Forecast served", metadata: [
            "requestID":  .string(requestID),
            "coordinate": .string(canonical),
        ])
        let body = ForecastResponseBody(
            result: forecast.result, coordinate: request.coordinate, activity: request.activity)
        return APIResponse(statusCode: 200, body: Self.json(body))
    }

    private static func response(for error: ForecastAPIError) -> APIResponse {
        APIResponse(statusCode: error.statusCode, body: json(ErrorResponseBody(error)))
    }

    private static func json<Body: Encodable>(_ body: Body) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601  // "2026-07-24T09:15:00Z", per the contract
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        // Encoding this module's own wire types can only fail on a programming error here —
        // crash loudly, same trusted-path philosophy as Core's internal-init preconditions.
        let data: Data = try! encoder.encode(body)
        return String(decoding: data, as: UTF8.self)
    }
}
