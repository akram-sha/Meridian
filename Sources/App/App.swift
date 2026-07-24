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
        let outcomes                         = await coordinator.fetch(locations: [location])

        let presenter: WeatherPresenter = WeatherPresenter()
        for (location, outcome) in zip([location], outcomes) {
            switch outcome {
            case .success(let forecast):
                print(presenter.present(forecast.result))
            case .failure(let error):
                print("Could not fetch forecast for \(location.name): \(error)")
            }
        }
    }
}