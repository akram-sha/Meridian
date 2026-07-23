import Foundation

/// Default `ForecastCache` for any long-lived process (CLI, iOS) that can hold its own
/// state between calls. Not suitable across separate Lambda execution environments —
/// use a shared backing store (e.g. a DynamoDB-backed `ForecastCache`) there instead.
public actor InMemoryForecastCache: ForecastCache {
    private struct Entry {
        let result:    WeatherResult
        let expiresAt: Date
    }

    private var entries: [ForecastCacheKey: Entry] = [:]
    private let ttl: TimeInterval
    private let now: @Sendable () -> Date

    public init(ttl: TimeInterval = 15 * 60, now: @escaping @Sendable () -> Date = Date.init) {
        self.ttl = ttl
        self.now = now
    }

    public func result(for key: ForecastCacheKey) async -> WeatherResult? {
        guard let entry = entries[key] else { return nil }
        guard entry.expiresAt > now() else {
            entries[key] = nil
            return nil
        }
        return entry.result
    }

    public func store(_ result: WeatherResult, for key: ForecastCacheKey) async {
        entries[key] = Entry(result: result, expiresAt: now().addingTimeInterval(ttl))
    }
}
