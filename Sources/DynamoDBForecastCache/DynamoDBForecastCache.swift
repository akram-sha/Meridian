import Core
import Foundation
import SotoDynamoDB

/// `ForecastCache` backed by a DynamoDB table, for use across separate Lambda execution
/// environments where `InMemoryForecastCache` can't share state. The item's `ttl` attribute
/// is DynamoDB's native expiry — the same mechanism doubles as the privacy control of not
/// retaining location query history past the cache window.
///
/// The table needs exactly one attribute: a String partition key named `pk`. Enable TTL on
/// the `ttl` attribute after creation (`aws dynamodb update-time-to-live`) — see
/// `misc/BACKEND_LAMBDA_PLAN.md` and `docker/localstack-init.sh` for setup.
public struct DynamoDBForecastCache: ForecastCache, Sendable {
    private let client: DynamoDB
    private let tableName: String
    private let ttl: TimeInterval
    private let now: @Sendable () -> Date

    public init(client: DynamoDB, tableName: String, ttl: TimeInterval = 15 * 60,
                now: @escaping @Sendable () -> Date = Date.init) {
        self.client = client
        self.tableName = tableName
        self.ttl = ttl
        self.now = now
    }

    public func result(for key: ForecastCacheKey) async -> WeatherResult? {
        guard let response = try? await client.getItem(
            key: ["pk": .s(Self.partitionKey(for: key))],
            tableName: tableName
        ) else { return nil }

        guard let item = response.item,
              case .s(let payload) = item["payload"] else { return nil }

        // DynamoDB TTL deletion is lazy (it can lag expiry by up to ~48 hours) and
        // GetItem still returns expired-but-undeleted items, so expiry has to be
        // enforced on read — mirroring InMemoryForecastCache's read-side check.
        guard case .n(let ttlString) = item["ttl"],
              let expiresAt = Double(ttlString),
              expiresAt > now().timeIntervalSince1970 else { return nil }

        return try? JSONDecoder().decode(WeatherResult.self, from: Data(payload.utf8))
    }

    public func store(_ result: WeatherResult, for key: ForecastCacheKey) async {
        guard let payload = try? JSONEncoder().encode(result),
              let payloadString = String(data: payload, encoding: .utf8) else { return }

        let expiresAt = Int(now().addingTimeInterval(ttl).timeIntervalSince1970)

        _ = try? await client.putItem(
            item: [
                "pk":      .s(Self.partitionKey(for: key)),
                "payload": .s(payloadString),
                "ttl":     .n(String(expiresAt)),
            ],
            tableName: tableName
        )
    }

    private static func partitionKey(for key: ForecastCacheKey) -> String {
        "coord#\(key.latitude)_\(key.longitude)"
    }
}
