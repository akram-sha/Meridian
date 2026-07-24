import Testing
@testable import Core

// MARK: - Test doubles

// Returns a WeatherResult whose air temperature equals the requested latitude.
// This lets tests verify that the coordinator passed the right coordinates
// to the service and paired the result with the right Location.
struct LatitudeEchoService: WeatherService, Sendable {
    func fetch(coordinate: Coordinate) async throws -> WeatherResult {
        WeatherResult(
            airTemperature: AirTemperature(celsius: coordinate.latitude),
            uvIndex:        UVIndex(value: 0),
            windSpeed:      WindSpeed(kmh: 0),
            weatherCode:    WeatherCode(raw: 1),
        )
    }
}

// Always throws — used to verify the coordinator surfaces failed fetches.
struct AlwaysFailingService: WeatherService, Sendable {
    enum Failure: Error { case always }
    func fetch(coordinate: Coordinate) async throws -> WeatherResult {
        throw Failure.always
    }
}

// Fails for one specific latitude, succeeds (via LatitudeEchoService) for all others.
// Used to verify a single failure does not affect the rest of the batch.
struct SelectiveFailureService: WeatherService, Sendable {
    let failLatitude: Double
    func fetch(coordinate: Coordinate) async throws -> WeatherResult {
        if coordinate.latitude == failLatitude { throw AlwaysFailingService.Failure.always }
        return WeatherResult(
            airTemperature: AirTemperature(celsius: coordinate.latitude),
            uvIndex:        UVIndex(value: 0),
            windSpeed:      WindSpeed(kmh: 0),
            weatherCode:    WeatherCode(raw: 1),
        )
    }
}

// Counts invocations so tests can assert whether the network was actually hit,
// as opposed to a result being served from cache.
actor CallCountingService: WeatherService {
    private(set) var callCount = 0

    func fetch(coordinate: Coordinate) async throws -> WeatherResult {
        callCount += 1
        return WeatherResult(
            airTemperature: AirTemperature(celsius: coordinate.latitude),
            uvIndex:        UVIndex(value: 0),
            windSpeed:      WindSpeed(kmh: 0),
            weatherCode:    WeatherCode(raw: 1),
        )
    }
}

// MARK: - Suite

@Suite("ForecastCoordinator")
struct ForecastCoordinatorTests {

    // MARK: - Result count

    @Test("Returns one forecast per location")
    func returnsOneForecastPerLocation() async throws {
        let coordinator = ForecastCoordinator(weatherService: StubWeatherService())
        let locations   = [
            try Location(name: "A", latitude: 52.37, longitude: 4.53),
            try Location(name: "B", latitude: 51.50, longitude: 4.90),
            try Location(name: "C", latitude: 50.85, longitude: 4.35),
        ]
        let forecasts = await coordinator.fetch(locations: locations)
        #expect(forecasts.count == 3)
    }

    @Test("Returns empty array for empty input")
    func emptyInputReturnsEmpty() async {
        let coordinator = ForecastCoordinator(weatherService: StubWeatherService())
        #expect(await coordinator.fetch(locations: []).isEmpty)
    }

    // MARK: - Location pairing

    @Test("Each forecast carries its source location name")
    func forecastCarriesSourceLocationName() async throws {
        let coordinator = ForecastCoordinator(weatherService: StubWeatherService())
        let location    = try Location(name: "Zandvoort", latitude: 52.37, longitude: 4.53)
        let forecast    = try #require(await coordinator.fetch(locations: [location]).first).get()

        #expect(forecast.location.name == "Zandvoort")
    }

    @Test("Coordinator passes correct coordinates to the service")
    func passesCorrectCoordinates() async throws {
        // LatitudeEchoService encodes the latitude it received as air temperature,
        // so if the forecast has air temp 42.0°C the right coordinate was used.
        let coordinator = ForecastCoordinator(weatherService: LatitudeEchoService())
        let location    = try Location(name: "Test", latitude: 42.0, longitude: 7.0)
        let forecast    = try #require(await coordinator.fetch(locations: [location]).first).get()

        #expect(abs(forecast.result.airTemperature.inCelsius - 42.0) < 0.001)
    }

    // MARK: - Failure handling

    @Test("A failed fetch surfaces as a failure result, not a silent drop")
    func failedFetchSurfacesAsFailure() async throws {
        let coordinator = ForecastCoordinator(weatherService: AlwaysFailingService())
        let locations   = [try Location(name: "A", latitude: 52.37, longitude: 4.53)]
        let results     = await coordinator.fetch(locations: locations)

        #expect(results.count == 1)
        #expect(throws: AlwaysFailingService.Failure.always) {
            _ = try #require(results.first).get()
        }
    }

    @Test("One failed fetch does not affect the rest of the batch, and results keep input order")
    func singleFailureDoesNotAffectBatch() async throws {
        let failLatitude = 89.0
        let coordinator  = ForecastCoordinator(weatherService: SelectiveFailureService(failLatitude: failLatitude))
        let locations    = [
            try Location(name: "Fail",    latitude: failLatitude, longitude: 0),
            try Location(name: "Success", latitude: 52.37,        longitude: 4.53),
        ]
        let results = await coordinator.fetch(locations: locations)

        #expect(results.count == 2)
        #expect(throws: AlwaysFailingService.Failure.always) {
            _ = try #require(results.first).get()
        }
        #expect(try #require(results.last).get().location.name == "Success")
    }

    @Test("Results are returned in input order despite concurrent fetching")
    func resultsPreserveInputOrder() async throws {
        let coordinator = ForecastCoordinator(weatherService: LatitudeEchoService())
        let locations   = [
            try Location(name: "A", latitude: 10.0, longitude: 0),
            try Location(name: "B", latitude: 20.0, longitude: 0),
            try Location(name: "C", latitude: 30.0, longitude: 0),
        ]
        let results   = await coordinator.fetch(locations: locations)
        let latitudes = try results.map { try $0.get().result.airTemperature.inCelsius }

        #expect(latitudes == [10.0, 20.0, 30.0])
    }

    // MARK: - Single-location fetch

    @Test("forecast(for:) propagates the service error")
    func singleForecastPropagatesError() async throws {
        let coordinator = ForecastCoordinator(weatherService: AlwaysFailingService())
        let location    = try Location(name: "A", latitude: 52.37, longitude: 4.53)

        await #expect(throws: AlwaysFailingService.Failure.always) {
            _ = try await coordinator.forecast(for: location)
        }
    }

    @Test("forecast(for:) serves from cache without hitting the service")
    func singleForecastServedFromCache() async throws {
        let service     = CallCountingService()
        let coordinator = ForecastCoordinator(weatherService: service, cache: InMemoryForecastCache())
        let location    = try Location(name: "Zandvoort", latitude: 52.37, longitude: 4.53)

        _ = try await coordinator.forecast(for: location)
        _ = try await coordinator.forecast(for: location)

        #expect(await service.callCount == 1)
    }

    // MARK: - Caching

    @Test("A second fetch for the same coordinates does not hit the service again")
    func secondFetchForSameCoordinatesIsServedFromCache() async throws {
        let service     = CallCountingService()
        let coordinator = ForecastCoordinator(weatherService: service, cache: InMemoryForecastCache())
        let location    = try Location(name: "Zandvoort", latitude: 52.37, longitude: 4.53)

        _ = await coordinator.fetch(locations: [location])
        _ = await coordinator.fetch(locations: [location])

        #expect(await service.callCount == 1)
    }

    @Test("Cache hits by coordinates — two independently constructed Location values at the same spot share a cache entry")
    func cacheHitsAcrossDistinctLocationValues() async throws {
        // Every request constructs its own Location value. The cache key must be
        // derived from the coordinates that repeat across requests, never from any
        // per-request identity (an earlier design keyed on a UUID minted per
        // Location and could never hit) — this pins that two separate constructions
        // for the same beach share one entry.
        let service     = CallCountingService()
        let coordinator = ForecastCoordinator(weatherService: service, cache: InMemoryForecastCache())

        let firstRequest  = try Location(name: "Zandvoort", latitude: 52.37, longitude: 4.53)
        let secondRequest = try Location(name: "Zandvoort", latitude: 52.37, longitude: 4.53)

        _ = await coordinator.fetch(locations: [firstRequest])
        _ = await coordinator.fetch(locations: [secondRequest])

        #expect(await service.callCount == 1)
    }

    @Test("A stored cache entry is used instead of calling the service")
    func prePopulatedCacheIsUsed() async throws {
        let cache = InMemoryForecastCache()
        let key   = ForecastCacheKey(coordinate: try Coordinate(latitude: 52.37, longitude: 4.53))
        await cache.store(
            WeatherResult(
                airTemperature: AirTemperature(celsius: 99.0),
                uvIndex:        UVIndex(value: 0),
                windSpeed:      WindSpeed(kmh: 0),
                weatherCode:    WeatherCode(raw: 1),
            ),
            for: key
        )

        let coordinator = ForecastCoordinator(weatherService: AlwaysFailingService(), cache: cache)
        let location    = try Location(name: "Zandvoort", latitude: 52.37, longitude: 4.53)
        let forecast    = try #require(await coordinator.fetch(locations: [location]).first).get()

        #expect(forecast.result.airTemperature.inCelsius == 99.0)
    }
}
