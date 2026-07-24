import Core
import Foundation
import Logging
import SotoDynamoDB

/// `ForecastCache` backed by a DynamoDB table, for use across separate Lambda execution
/// environments where `InMemoryForecastCache` can't share state. The item's `ttl` attribute
/// is DynamoDB's native expiry — the same mechanism doubles as the privacy control of not
/// retaining location query history past the cache window.
///
/// The table needs exactly one attribute: a String partition key named `pk`. Enable TTL on
/// the `ttl` attribute after creation (`aws dynamodb update-time-to-live`) — see
/// `misc/BACKEND_LAMBDA_PLAN.md` and `docker/localstack-init.sh` for setup.
///
/// Fails open on every AWS error: an outage degrades to "always cache miss" rather than
/// breaking the app. Each failure is logged at warning level so the degradation is visible
/// in staging/production instead of silent.
public struct DynamoDBForecastCache: ForecastCache, Sendable {
    private let client: DynamoDB
    private let tableName: String
    private let ttl: TimeInterval
    private let now: @Sendable () -> Date
    private let logger: Logger

    public init(client: DynamoDB, tableName: String, ttl: TimeInterval = 15 * 60,
                now: @escaping @Sendable () -> Date = Date.init,
                logger: Logger = Logger(label: "meridian.forecast-cache")) {
        self.client = client
        self.tableName = tableName
        self.ttl = ttl
        self.now = now
        self.logger = logger
    }

    public func result(for key: ForecastCacheKey) async -> WeatherResult? {
        let pk = Self.partitionKey(for: key)
        let response: DynamoDB.GetItemOutput
        do {
            response = try await client.getItem(key: ["pk": .s(pk)], tableName: tableName)
        } catch {
            logger.warning("Forecast cache read failed open — treating as a miss", metadata: [
                "pk":    .string(pk),
                "error": .string(String(describing: error)),
            ])
            return nil
        }

        guard let item = response.item,
              case .s(let payload) = item["payload"] else { return nil }

        // DynamoDB TTL deletion is lazy (it can lag expiry by up to ~48 hours) and
        // GetItem still returns expired-but-undeleted items, so expiry has to be
        // enforced on read — mirroring InMemoryForecastCache's read-side check.
        guard case .n(let ttlString) = item["ttl"],
              let expiresAt = Double(ttlString),
              expiresAt > now().timeIntervalSince1970 else { return nil }

        do {
            return try JSONDecoder().decode(WeatherResult.self, from: Data(payload.utf8))
        } catch {
            logger.warning("Corrupted forecast cache payload — treating as a miss", metadata: [
                "pk":    .string(pk),
                "error": .string(String(describing: error)),
            ])
            return nil
        }
    }

    public func store(_ result: WeatherResult, for key: ForecastCacheKey) async {
        let pk = Self.partitionKey(for: key)
        guard let payload = try? JSONEncoder().encode(result),
              let payloadString = String(data: payload, encoding: .utf8) else {
            logger.warning("Failed to encode forecast for caching — entry not stored", metadata: [
                "pk": .string(pk),
            ])
            return
        }

        let expiresAt = Int(now().addingTimeInterval(ttl).timeIntervalSince1970)

        do {
            _ = try await client.putItem(
                item: [
                    "pk":      .s(pk),
                    "payload": .s(payloadString),
                    "ttl":     .n(String(expiresAt)),
                ],
                tableName: tableName
            )
        } catch {
            logger.warning("Forecast cache write failed open — entry not stored", metadata: [
                "pk":    .string(pk),
                "error": .string(String(describing: error)),
            ])
        }
    }

    private static func partitionKey(for key: ForecastCacheKey) -> String {
        // Canonical fixed two-decimal strings, not Double interpolation — Double's
        // description is coupled to Swift's shortest-round-trip algorithm and would
        // key "-0.0" and "0.0" differently. Rounded coordinates are the only location
        // data that may appear in a key or a log line (see Coordinate).
        "coord#\(key.coordinate.canonicalLatitude)_\(key.coordinate.canonicalLongitude)"
    }
}
