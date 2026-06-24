public protocol MarineService: Sendable {
    func fetch(latitude: Double, longitude: Double) async throws -> MarineConditions
}