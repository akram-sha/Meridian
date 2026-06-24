public struct StubMarineService: MarineService, Sendable {
    public init() {}

    public func fetch(latitude: Double, longitude: Double) async throws -> MarineConditions {
        MarineConditions(
            waterTemperature: WaterTemperature(celsius: 18.0),
            waveHeight:       WaveHeight(metres: 0.3)
        )
    }
}