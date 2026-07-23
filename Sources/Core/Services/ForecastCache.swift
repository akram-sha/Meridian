/// Cache key derived from coordinates, not from `Location.id`.
///
/// `Location.init` mints a fresh random `UUID` on every call, including for two requests
/// carrying the same coordinates — keying a cache on `Location.id` would never hit. Rounding
/// to two decimal places (~1 km) reuses the same precision already applied before any
/// third-party API call, so nearby requests share a cache entry and no request ever
/// contributes higher-precision coordinates than a cache key already carries.
public struct ForecastCacheKey: Sendable, Hashable {
    public let latitude:  Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude  = (latitude  * 100).rounded() / 100
        self.longitude = (longitude * 100).rounded() / 100
    }
}

public protocol ForecastCache: Sendable {
    func result(for key: ForecastCacheKey) async -> WeatherResult?
    func store(_ result: WeatherResult, for key: ForecastCacheKey) async
}
