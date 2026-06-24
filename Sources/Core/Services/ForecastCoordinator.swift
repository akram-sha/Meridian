public struct ForecastCoordinator: Sendable {
    private let weatherService: any WeatherService

    public init(weatherService: any WeatherService) {
        self.weatherService = weatherService
    }

    public func fetch(locations: [Location]) async -> [LocationForecast] {
        await withTaskGroup(of: LocationForecast?.self) { group in
            for location in locations {
                group.addTask {
                    guard let result = try? await self.weatherService.fetch(
                        latitude:  location.latitude,
                        longitude: location.longitude
                    ) else { return nil }
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
