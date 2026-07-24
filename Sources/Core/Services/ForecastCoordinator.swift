public struct ForecastCoordinator: Sendable {
    private let weatherService: any WeatherService
    private let cache: any ForecastCache

    public init(weatherService: any WeatherService, cache: any ForecastCache = InMemoryForecastCache()) {
        self.weatherService = weatherService
        self.cache = cache
    }

    /// Cache-aside fetch for a single location. Service failures propagate to the
    /// caller — a CLI prints them, an API handler maps them to a 5xx response.
    public func forecast(for location: Location) async throws -> LocationForecast {
        let key = ForecastCacheKey(coordinate: location.coordinate)

        if let cached = await cache.result(for: key) {
            return LocationForecast(location: location, result: cached)
        }

        let result = try await weatherService.fetch(coordinate: location.coordinate)
        await cache.store(result, for: key)
        return LocationForecast(location: location, result: result)
    }

    /// Concurrent multi-location fetch: one `Result` per input location, in input
    /// order. Failures stay visible to the caller instead of being silently dropped —
    /// an API must distinguish "upstream fetch failed" from an empty result set.
    public func fetch(locations: [Location]) async -> [Result<LocationForecast, any Error>] {
        await withTaskGroup(of: (Int, Result<LocationForecast, any Error>).self) { group in
            for (index, location) in locations.enumerated() {
                group.addTask {
                    do {
                        return (index, .success(try await self.forecast(for: location)))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }
            var results = [Result<LocationForecast, any Error>?](repeating: nil, count: locations.count)
            for await (index, result) in group {
                results[index] = result
            }
            return results.compactMap { $0 }
        }
    }
}
