/// Every error response the `/v1/forecast` handler can produce itself. The wire contract
/// also lists 403 (bad/missing API key) and 429 (`RATE_LIMITED`), but API Gateway emits
/// those before the handler runs — they never originate here.
public enum ForecastAPIError: Error, Equatable, Sendable {
    case coordinateOutOfRange(message: String)
    case coordinateTooPrecise(message: String)
    case unsupportedActivity(message: String)
    case upstreamUnavailable(message: String)

    /// The machine contract — stable across releases; clients branch on this.
    public var code: String {
        switch self {
        case .coordinateOutOfRange: return "COORDINATE_OUT_OF_RANGE"
        case .coordinateTooPrecise: return "COORDINATE_TOO_PRECISE"
        case .unsupportedActivity:  return "UNSUPPORTED_ACTIVITY"
        case .upstreamUnavailable:  return "UPSTREAM_UNAVAILABLE"
        }
    }

    /// Human-readable and deliberately unstable — never part of the machine contract.
    public var message: String {
        switch self {
        case .coordinateOutOfRange(let message),
             .coordinateTooPrecise(let message),
             .unsupportedActivity(let message),
             .upstreamUnavailable(let message):
            return message
        }
    }

    public var statusCode: Int {
        switch self {
        case .coordinateOutOfRange, .coordinateTooPrecise, .unsupportedActivity:
            return 400
        case .upstreamUnavailable:
            return 502
        }
    }
}
