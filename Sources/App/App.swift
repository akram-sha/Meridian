import ArgumentParser
import Core
import Presentation

@main
struct App: AsyncParsableCommand {
    @Option(name: .shortAndLong, help: "Location name")
    var name: String = "Custom location"

    @Argument(help: "Latitude")
    var latitude: Double

    @Argument(help: "Longitude")
    var longitude: Double

    mutating func run() async throws {
        let service:     OpenMeteoService    = OpenMeteoService(marineService: OpenMarineService())
        let coordinator: ForecastCoordinator = ForecastCoordinator(weatherService: service)
        let location:    Location            = try Location(name: name, latitude: latitude, longitude: longitude)
        let forecasts:   [LocationForecast]  = await coordinator.fetch(locations: [location])

        let presenter: WeatherPresenter = WeatherPresenter()
        for forecast: LocationForecast in forecasts {
            print(presenter.present(forecast.result))
        }
    }
}