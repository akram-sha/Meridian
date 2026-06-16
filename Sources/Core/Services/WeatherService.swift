public protocol WeatherService: Sendable {
    func fetch(latitude: Double, longitude: Double) async throws -> WeatherResult
}