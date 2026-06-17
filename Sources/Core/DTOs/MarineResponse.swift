internal struct MarineResponse: Decodable {
    let current: Current

    struct Current: Decodable {
        let seaSurfaceTemperature: Double

        enum CodingKeys: String, CodingKey {
            case seaSurfaceTemperature = "sea_surface_temperature"
        }
    }

    func toWaterTemperature() -> WaterTemperature {
        WaterTemperature(celsius: current.seaSurfaceTemperature)
    }
}