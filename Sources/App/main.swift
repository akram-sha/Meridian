import Core

//let service: any WeatherService = StubWeatherService()
let service: any WeatherService = OpenMeteoService()

let weather = try await service.fetch(latitude: 52.37, longitude: 4.90)
print(WeatherPresenter().present(weather))