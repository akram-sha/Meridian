public struct ForecastCoordinator: Sendable {
    private let weatherService: any WeatherService
    private let cache: any ForecastCache

    public init(weatherService: any WeatherService, cache: any ForecastCache = InMemoryForecastCache()) {
        self.weatherService = weatherService
        self.cache = cache
    }

    public func fetch(locations: [Location]) async -> [LocationForecast] {
        await withTaskGroup(of: LocationForecast?.self) { group in
            for location in locations {
                group.addTask {
                    let key = ForecastCacheKey(coordinate: location.coordinate)

                    if let cached = await self.cache.result(for: key) {
                        return LocationForecast(location: location, result: cached)
                    }

                    guard let result = try? await self.weatherService.fetch(
                        coordinate: location.coordinate
                    ) else { return nil }

                    await self.cache.store(result, for: key)
                    return LocationForecast(location: location, result: result)
                }
            }
            var forecasts: [LocationForecast] = []
            for await forecast in group {
                if let forecast { forecasts.append(forecast) }
            }
            return forecasts
        }
    }
}
