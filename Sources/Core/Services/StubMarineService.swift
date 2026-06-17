public struct StubMarineService: MarineService, Sendable {
    public init() {}

    public func fetch(latitude: Double, longitude: Double) async throws -> WaterTemperature {
        WaterTemperature(celsius: 18.0)
    }
}