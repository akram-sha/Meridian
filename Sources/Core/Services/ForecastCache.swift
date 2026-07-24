/// Cache key derived from a validated, privacy-rounded `Coordinate` — never from
/// `Location` identity or any per-request-unique value, so repeated queries for the
/// same beach share an entry. Coordinate rounding (~1 km) doubles as the cache
/// granularity, and no key ever carries higher precision than what is already sent
/// to third-party APIs.
///
/// A wrapper type (rather than `Coordinate` used directly) so future key dimensions
/// — e.g. per-activity caching — extend this struct without changing the
/// `ForecastCache` protocol.
public struct ForecastCacheKey: Sendable, Hashable {
    public let coordinate: Coordinate

    public init(coordinate: Coordinate) {
        self.coordinate = coordinate
    }
}

public protocol ForecastCache: Sendable {
    func result(for key: ForecastCacheKey) async -> WeatherResult?
    func store(_ result: WeatherResult, for key: ForecastCacheKey) async
}
