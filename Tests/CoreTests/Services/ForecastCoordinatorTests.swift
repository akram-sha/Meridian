import Testing
@testable import Core

// MARK: - Test doubles

// Returns a WeatherResult whose air temperature equals the requested latitude.
// This lets tests verify that the coordinator passed the right coordinates
// to the service and paired the result with the right Location.
struct LatitudeEchoService: WeatherService, Sendable {
    func fetch(latitude: Double, longitude: Double) async throws -> WeatherResult {
        WeatherResult(
            airTemperature: AirTemperature(celsius: latitude),
            uvIndex:        UVIndex(value: 0),
            windSpeed:      WindSpeed(kmh: 0),
            weatherCode:    WeatherCode(raw: 1),
        )
    }
}

// Always throws — used to verify the coordinator silently drops failed fetches.
struct AlwaysFailingService: WeatherService, Sendable {
    enum Failure: Error { case always }
    func fetch(latitude: Double, longitude: Double) async throws -> WeatherResult {
        throw Failure.always
    }
}

// Fails for one specific latitude, succeeds (via LatitudeEchoService) for all others.
// Used to verify a single failure does not affect the rest of the batch.
struct SelectiveFailureService: WeatherService, Sendable {
    let failLatitude: Double
    func fetch(latitude: Double, longitude: Double) async throws -> WeatherResult {
        if latitude == failLatitude { throw AlwaysFailingService.Failure.always }
        return WeatherResult(
            airTemperature: AirTemperature(celsius: latitude),
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
    func returnsOneForecastPerLocation() async {
        let coordinator = ForecastCoordinator(weatherService: StubWeatherService())
        let locations   = [
            Location(name: "A", latitude: 52.37, longitude: 4.53),
            Location(name: "B", latitude: 51.50, longitude: 4.90),
            Location(name: "C", latitude: 50.85, longitude: 4.35),
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

    @Test("Each forecast carries its source location ID")
    func forecastCarriesSourceLocationID() async {
        let coordinator = ForecastCoordinator(weatherService: StubWeatherService())
        let location    = Location(name: "Zandvoort", latitude: 52.37, longitude: 4.53)
        let forecasts   = await coordinator.fetch(locations: [location])

        #expect(forecasts.first?.location.id == location.id)
    }

    @Test("Each forecast carries its source location name")
    func forecastCarriesSourceLocationName() async {
        let coordinator = ForecastCoordinator(weatherService: StubWeatherService())
        let location    = Location(name: "Zandvoort", latitude: 52.37, longitude: 4.53)
        let forecasts   = await coordinator.fetch(locations: [location])

        #expect(forecasts.first?.location.name == "Zandvoort")
    }

    @Test("Coordinator passes correct coordinates to the service")
    func passesCorrectCoordinates() async {
        // LatitudeEchoService encodes the latitude it received as air temperature,
        // so if the forecast has air temp 42.0°C the right coordinate was used.
        let coordinator = ForecastCoordinator(weatherService: LatitudeEchoService())
        let location    = Location(name: "Test", latitude: 42.0, longitude: 7.0)
        let forecasts   = await coordinator.fetch(locations: [location])

        #expect(abs((forecasts.first?.result.airTemperature.inCelsius ?? -1) - 42.0) < 0.001)
    }

    // MARK: - Failure handling

    @Test("Failed fetch is silently dropped")
    func failedFetchIsDropped() async {
        let coordinator = ForecastCoordinator(weatherService: AlwaysFailingService())
        let locations   = [Location(name: "A", latitude: 52.37, longitude: 4.53)]
        #expect(await coordinator.fetch(locations: locations).isEmpty)
    }

    @Test("One failed fetch does not affect the rest of the batch")
    func singleFailureDoesNotAffectBatch() async {
        let failLatitude = 99.0
        let coordinator  = ForecastCoordinator(weatherService: SelectiveFailureService(failLatitude: failLatitude))
        let locations    = [
            Location(name: "Fail",    latitude: failLatitude, longitude: 0),
            Location(name: "Success", latitude: 52.37,        longitude: 4.53),
        ]
        let forecasts = await coordinator.fetch(locations: locations)

        #expect(forecasts.count == 1)
        #expect(forecasts.first?.location.name == "Success")
    }
}