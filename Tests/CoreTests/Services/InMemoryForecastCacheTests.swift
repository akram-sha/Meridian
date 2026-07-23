import Foundation
import Testing
@testable import Core

// Mutable clock the tests can advance. `now` closures must be @Sendable, so a
// captured `var` won't compile under Swift 6 strict concurrency — this reference
// type stands in for one.
final class TestClock: @unchecked Sendable {
    var date: Date
    init(_ date: Date) { self.date = date }
    func advance(by seconds: TimeInterval) { date = date.addingTimeInterval(seconds) }
}

@Suite("InMemoryForecastCache")
struct InMemoryForecastCacheTests {

    private static let sampleResult = WeatherResult(
        airTemperature: AirTemperature(celsius: 22.5),
        uvIndex:        UVIndex(value: 6.8),
        windSpeed:      WindSpeed(kmh: 12.0),
        weatherCode:    WeatherCode(raw: 1),
    )

    // MARK: - Basic get/store

    @Test("Miss on an empty cache")
    func missOnEmptyCache() async {
        let cache = InMemoryForecastCache()
        let key   = ForecastCacheKey(latitude: 52.37, longitude: 4.53)
        #expect(await cache.result(for: key) == nil)
    }

    @Test("Hit after store")
    func hitAfterStore() async {
        let cache = InMemoryForecastCache()
        let key   = ForecastCacheKey(latitude: 52.37, longitude: 4.53)
        await cache.store(Self.sampleResult, for: key)

        let cached = await cache.result(for: key)
        #expect(cached?.airTemperature.inCelsius == 22.5)
    }

    // MARK: - TTL expiry

    @Test("Entry is still fresh just before TTL elapses")
    func freshJustBeforeTTL() async {
        let clock = TestClock(.init(timeIntervalSince1970: 0))
        let cache = InMemoryForecastCache(ttl: 60, now: { clock.date })
        let key   = ForecastCacheKey(latitude: 52.37, longitude: 4.53)

        await cache.store(Self.sampleResult, for: key)
        clock.advance(by: 59)

        #expect(await cache.result(for: key) != nil)
    }

    @Test("Entry expires once TTL has elapsed")
    func expiresAfterTTL() async {
        let clock = TestClock(.init(timeIntervalSince1970: 0))
        let cache = InMemoryForecastCache(ttl: 60, now: { clock.date })
        let key   = ForecastCacheKey(latitude: 52.37, longitude: 4.53)

        await cache.store(Self.sampleResult, for: key)
        clock.advance(by: 61)

        #expect(await cache.result(for: key) == nil)
    }

    // MARK: - Key rounding (mirrors the coordinate-rounding privacy rule)

    @Test("Coordinates within rounding tolerance share a cache entry")
    func nearbyCoordinatesShareEntry() async {
        let cache = InMemoryForecastCache()
        let writeKey = ForecastCacheKey(latitude: 52.3717, longitude: 4.5333)
        await cache.store(Self.sampleResult, for: writeKey)

        let readKey = ForecastCacheKey(latitude: 52.3721, longitude: 4.5328)
        #expect(await cache.result(for: readKey) != nil)
    }

    @Test("Coordinates a full cell apart do not share a cache entry")
    func distantCoordinatesDoNotShareEntry() async {
        let cache = InMemoryForecastCache()
        let writeKey = ForecastCacheKey(latitude: 52.37, longitude: 4.53)
        await cache.store(Self.sampleResult, for: writeKey)

        let readKey = ForecastCacheKey(latitude: 51.50, longitude: 4.90)
        #expect(await cache.result(for: readKey) == nil)
    }
}
