internal struct MarineResponse: Decodable {
    let current: Current

    struct Current: Decodable {
        let seaSurfaceTemperature: Double
        let waveHeight:            Double?  // optional: not all locations return it.
        enum CodingKeys: String, CodingKey {
            case seaSurfaceTemperature = "sea_surface_temperature"
            case waveHeight            = "wave_height"
        }
    }

    func toMarineConditions() -> MarineConditions {
        MarineConditions(
            waterTemperature: WaterTemperature(celsius: current.seaSurfaceTemperature),
            waveHeight:       current.waveHeight.map { WaveHeight(metres: $0) }
        )
    }
}