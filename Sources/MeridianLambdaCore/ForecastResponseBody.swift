import Core
import Foundation

/// The 200 body of `GET /v1/forecast` — the only type that knows the v1 wire shape of a
/// successful response. This is the handler-side mirror of Core's DTO-boundary rule:
/// nothing outside this module sees these key names, and Core never sees them at all.
public struct ForecastResponseBody: Encodable, Sendable {
    public struct Measurements: Encodable, Sendable {
        public let airTemperatureC:   Double
        public let waterTemperatureC: Double?
        public let waveHeightM:       Double?
        public let uvIndex:           Double
        public let windSpeedKmh:      Double
        public let weatherCode:       Int

        private enum CodingKeys: String, CodingKey {
            case airTemperatureC, waterTemperatureC, waveHeightM
            case uvIndex, windSpeedKmh, weatherCode
        }

        // Manual encode so absent marine values appear as explicit `null`s — the contract
        // documents them as null during the `pending` degradation, not as missing keys.
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(airTemperatureC,   forKey: .airTemperatureC)
            try container.encode(waterTemperatureC, forKey: .waterTemperatureC)
            try container.encode(waveHeightM,       forKey: .waveHeightM)
            try container.encode(uvIndex,           forKey: .uvIndex)
            try container.encode(windSpeedKmh,      forKey: .windSpeedKmh)
            try container.encode(weatherCode,       forKey: .weatherCode)
        }
    }

    public struct CoordinateBody: Encodable, Sendable {
        public let latitude:  Double
        public let longitude: Double
    }

    public let verdict:      String
    public let reasons:      [String]
    public let measurements: Measurements
    public let coordinate:   CoordinateBody
    public let activity:     String
    public let fetchedAt:    Date

    public init(result: WeatherResult, coordinate: Coordinate, activity: Activity) {
        // `pending` is the wire form of `swimmingConditions == nil` (inland coordinate /
        // marine data unavailable) — folded into `verdict` so clients keep a single switch.
        switch result.swimmingConditions?.verdict {
        case nil:
            self.verdict = "pending"
            self.reasons = []
        case .go:
            self.verdict = "go"
            self.reasons = []
        case .caution(let reasons):
            self.verdict = "caution"
            self.reasons = reasons
        case .noGo(let reasons):
            self.verdict = "noGo"
            self.reasons = reasons
        }

        self.measurements = Measurements(
            airTemperatureC:   result.airTemperature.inCelsius,
            waterTemperatureC: result.waterTemperature?.inCelsius,
            waveHeightM:       result.waveHeight?.inMeters,
            uvIndex:           result.uvIndex.value,
            windSpeedKmh:      result.windSpeed.inKmh,
            weatherCode:       result.weatherCode.raw
        )

        // Echo the rounded values actually used, so clients can display/cache what was
        // really queried.
        self.coordinate = CoordinateBody(
            latitude: coordinate.latitude, longitude: coordinate.longitude)

        // Explicit mapping, not String(describing:) — the wire value must stay stable
        // even if the enum case is ever renamed.
        switch activity {
        case .swimming: self.activity = "swimming"
        case .diving:   self.activity = "diving"
        case .surfing:  self.activity = "surfing"
        }

        self.fetchedAt = result.fetchedAt
    }
}

/// The error envelope shared by every handler-emitted failure (wire contract: Errors).
public struct ErrorResponseBody: Encodable, Sendable {
    public struct Detail: Encodable, Sendable {
        public let code:    String
        public let message: String
    }

    public let error: Detail

    public init(_ apiError: ForecastAPIError) {
        self.error = Detail(code: apiError.code, message: apiError.message)
    }
}
