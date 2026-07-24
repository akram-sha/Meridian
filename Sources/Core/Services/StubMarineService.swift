public struct StubMarineService: MarineService, Sendable {
    public init() {}

    public func fetch(coordinate: Coordinate) async throws -> MarineConditions {
        MarineConditions(
            waterTemperature: WaterTemperature(celsius: 18.0),
            waveHeight:       WaveHeight(meters: 0.3),
        )
    }
}