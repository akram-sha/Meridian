public protocol WeatherService: Sendable {
    func fetch(coordinate: Coordinate) async throws -> WeatherResult
}
