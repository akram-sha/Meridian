import Core
#if canImport(Glibc)
import Glibc
#elseif canImport(Darwin)
import Darwin
#endif

let service: any WeatherService = OpenMeteoService(marineService: OpenMarineService())

do {
    let weather = try await service.fetch(latitude: 52.37, longitude: 4.90)
    print(WeatherPresenter().present(weather))
} catch let error as OpenMeteoService.ServiceError {
    switch error {
    case .malformedURL:
        print("Error: could not construct request URL")
    case .invalidResponse:
        print("Error: server returned an unexpected response")
    case .httpError(let statusCode):
        print("Error: server returned HTTP \(statusCode)")
    }
    exit(1)
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}