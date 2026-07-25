public struct Location: Sendable {
    public let name: String
    public let coordinate: Coordinate

    public init(name: String, coordinate: Coordinate) {
        self.name = name
        self.coordinate = coordinate
    }

    /// Convenience for callers holding raw degrees (CLI arguments, a future request handler).
    /// Throws `CoordinateError` on out-of-range input.
    public init(name: String, latitude: Double, longitude: Double) throws {
        self.init(name: name, coordinate: try Coordinate(latitude: latitude, longitude: longitude))
    }

    public var latitude: Double { coordinate.latitude }
    public var longitude: Double { coordinate.longitude }
}
