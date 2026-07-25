import Foundation
import Testing
@testable import MeridianLambdaCore
@testable import Core

// End-to-end over the transport-neutral pipeline: query parameters in, contract JSON out.
// Stubs stand in for the weather service (the project's stubs-over-mocks discipline);
// no Lambda runtime or LocalStack involved — that split is deliberate.
@Suite("ForecastAPI")
struct ForecastAPITests {

    // MARK: - Stubs and fixtures

    private struct FixedWeatherService: WeatherService {
        let result: WeatherResult
        func fetch(coordinate: Coordinate) async throws -> WeatherResult { result }
    }

    private struct FailingWeatherService: WeatherService {
        struct Failure: Error {}
        func fetch(coordinate: Coordinate) async throws -> WeatherResult { throw Failure() }
    }

    /// 2026-07-24T09:15:00Z — the wire contract's own example timestamp.
    private static let fetchedAt: Date = Date(timeIntervalSince1970: 1_784_884_500)

    private func makeResult(
        air: Double = 24.0,
        water: Double? = 22.0,   // .ideal — clean baseline, verdict .go
        wave: Double? = 0.3,
        uv: Double = 0.0,
        wind: Double = 0.0,
        code: Int = 1
    ) -> WeatherResult {
        WeatherResult(
            airTemperature:   AirTemperature(celsius: air),
            waterTemperature: water.map { WaterTemperature(celsius: $0) },
            waveHeight:       wave.map { WaveHeight(meters: $0) },
            uvIndex:          UVIndex(value: uv),
            windSpeed:        WindSpeed(kmh: wind),
            weatherCode:      WeatherCode(raw: code),
            fetchedAt:        Self.fetchedAt
        )
    }

    private func api(returning result: WeatherResult) -> ForecastAPI {
        ForecastAPI(coordinator: ForecastCoordinator(
            weatherService: FixedWeatherService(result: result)))
    }

    private func handle(
        _ api: ForecastAPI,
        latitude: String = "52.37", longitude: String = "4.53", activity: String = "swimming"
    ) async -> APIResponse {
        await api.handle(
            queryParameters: [
                "latitude": latitude, "longitude": longitude, "activity": activity,
            ],
            requestID: "test-request"
        )
    }

    private func bodyJSON(_ response: APIResponse) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: Data(response.body.utf8))
        return try #require(object as? [String: Any])
    }

    // MARK: - 200: contract shape

    @Test func happyPathReturnsFullContractShape() async throws {
        let response = await handle(api(returning: makeResult()))
        #expect(response.statusCode == 200)

        let json = try bodyJSON(response)
        #expect(json["verdict"] as? String == "go")
        #expect((json["reasons"] as? [Any])?.isEmpty == true)
        #expect(json["activity"] as? String == "swimming")
        #expect(json["fetchedAt"] as? String == "2026-07-24T09:15:00Z")

        let measurements = try #require(json["measurements"] as? [String: Any])
        #expect(measurements["airTemperatureC"] as? Double == 24.0)
        #expect(measurements["waterTemperatureC"] as? Double == 22.0)
        #expect(measurements["waveHeightM"] as? Double == 0.3)
        #expect(measurements["uvIndex"] as? Double == 0.0)
        #expect(measurements["windSpeedKmh"] as? Double == 0.0)
        #expect(measurements["weatherCode"] as? Int == 1)

        let coordinate = try #require(json["coordinate"] as? [String: Any])
        #expect(coordinate["latitude"] as? Double == 52.37)
        #expect(coordinate["longitude"] as? Double == 4.53)
    }

    @Test func cautionReasonsPassThroughVerbatim() async throws {
        let result = makeResult(uv: 6.7)  // .high — one caution reason from the UV rule
        guard case .caution(let expectedReasons) = result.swimmingConditions!.verdict else {
            Issue.record("fixture no longer produces a caution verdict")
            return
        }

        let json = try bodyJSON(await handle(api(returning: result)))
        #expect(json["verdict"] as? String == "caution")
        #expect(json["reasons"] as? [String] == expectedReasons)
    }

    @Test func thunderstormMapsToNoGo() async throws {
        let result = makeResult(code: 95)
        guard case .noGo(let expectedReasons) = result.swimmingConditions!.verdict else {
            Issue.record("fixture no longer produces a noGo verdict")
            return
        }

        let json = try bodyJSON(await handle(api(returning: result)))
        #expect(json["verdict"] as? String == "noGo")
        #expect(json["reasons"] as? [String] == expectedReasons)
    }

    // MARK: - 200: pending degradation (inland coordinate / marine outage)

    @Test func missingWaterTemperatureIsPendingWithExplicitNulls() async throws {
        let response = await handle(api(returning: makeResult(water: nil, wave: nil)))
        #expect(response.statusCode == 200)

        let json = try bodyJSON(response)
        #expect(json["verdict"] as? String == "pending")
        #expect((json["reasons"] as? [Any])?.isEmpty == true)

        // The contract documents these as explicit nulls, not missing keys.
        let measurements = try #require(json["measurements"] as? [String: Any])
        #expect(measurements["waterTemperatureC"] is NSNull)
        #expect(measurements["waveHeightM"] is NSNull)
    }

    @Test func partialMarineOutageStillYieldsRealVerdict() async throws {
        let json = try bodyJSON(await handle(api(returning: makeResult(wave: nil))))
        #expect(json["verdict"] as? String == "go")

        let measurements = try #require(json["measurements"] as? [String: Any])
        #expect(measurements["waterTemperatureC"] as? Double == 22.0)
        #expect(measurements["waveHeightM"] is NSNull)
    }

    // MARK: - 400s: parse failures surface as the contract's error envelope

    @Test func tooPreciseCoordinateIs400WithContractCode() async throws {
        let response = await handle(api(returning: makeResult()), latitude: "52.3717")
        #expect(response.statusCode == 400)

        let error = try #require(try bodyJSON(response)["error"] as? [String: Any])
        #expect(error["code"] as? String == "COORDINATE_TOO_PRECISE")
        #expect(error["message"] as? String
            == "latitude must have at most 2 decimal places, got 52.3717")
    }

    @Test func outOfRangeCoordinateIs400WithContractCode() async throws {
        let response = await handle(api(returning: makeResult()), latitude: "99")
        #expect(response.statusCode == 400)

        let error = try #require(try bodyJSON(response)["error"] as? [String: Any])
        #expect(error["code"] as? String == "COORDINATE_OUT_OF_RANGE")
        #expect(error["message"] as? String == "latitude must be between -90 and 90, got 99.0")
    }

    @Test func unsupportedActivityIs400WithContractCode() async throws {
        let response = await handle(api(returning: makeResult()), activity: "surfing")
        #expect(response.statusCode == 400)

        let error = try #require(try bodyJSON(response)["error"] as? [String: Any])
        #expect(error["code"] as? String == "UNSUPPORTED_ACTIVITY")
    }

    // MARK: - 502: upstream failure

    @Test func upstreamFailureIs502WithContractCode() async throws {
        let api = ForecastAPI(coordinator: ForecastCoordinator(
            weatherService: FailingWeatherService()))
        let response = await handle(api)
        #expect(response.statusCode == 502)

        let error = try #require(try bodyJSON(response)["error"] as? [String: Any])
        #expect(error["code"] as? String == "UPSTREAM_UNAVAILABLE")
        #expect(error["message"] as? String == "forecast provider request failed")
    }
}
