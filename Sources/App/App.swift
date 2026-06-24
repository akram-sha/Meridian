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
        let service     = OpenMeteoService(marineService: OpenMarineService())
        let coordinator = ForecastCoordinator(weatherService: service)
        let location    = Location(name: name, latitude: latitude, longitude: longitude)
        let forecasts   = await coordinator.fetch(locations: [location])

        let presenter = WeatherPresenter()
        for forecast in forecasts {
            print(presenter.present(forecast.result))
        }
    }
}