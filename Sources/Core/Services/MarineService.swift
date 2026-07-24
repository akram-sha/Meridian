public protocol MarineService: Sendable {
    func fetch(coordinate: Coordinate) async throws -> MarineConditions
}
