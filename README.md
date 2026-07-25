# Meridian

A Swift package that answers one question for any coastal coordinate: **is it safe to swim here right now?**

Meridian fetches real-time weather and marine data, runs it through a layered rule engine, and returns a structured `Verdict` — `go`, `caution(reasons:)`, or `noGo(reasons:)` — with human-readable explanations for every flag raised. Diving and surfing verdicts are in progress. An iOS app is the end target.

---

## Setup

### Prerequisites

- **Swift 6.1** or later (`swift --version`). Package.swift declares `swift-tools-version: 6.1`; an older toolchain won't resolve the package.
- **Docker** — only if you're working on `DynamoDBForecastCache` and want to run its integration tests against LocalStack. Not needed for the CLI, `Core`, or `Presentation` — the standard test suite has no Docker dependency.

### Clone, build, test

```bash
git clone https://github.com/akram-sha/Meridian.git
cd Meridian
swift build
swift test
```

Expect a clean build and **214 passing tests**, no network or Docker access required — every `WeatherService`/`MarineService`/`ForecastCache` test runs against an in-module stub, and the Lambda handler's pipeline is tested through `MeridianLambdaCore` without any Lambda runtime.

### Run the CLI

```bash
swift run App --name "Bondi Beach" 151.2744 -33.8908
```

```
Bondi Beach
Water temperature: 21.3 °C (70.3 °F)
Wave height: 0.8 m (2.6 ft)
Wind: 18.2 km/h (11.3 mph, 9.8 kn)
UV index: 6.4

Verdict: Caution
  · UV index 6.4 is high — sun protection required
```

This hits the real Open-Meteo API (no key required) — coordinates outside its marine grid (e.g. inland) degrade gracefully to "Water Temp: unavailable" rather than failing.

### Optional: DynamoDB cache adapter (LocalStack)

`DynamoDBForecastCache` (`Sources/DynamoDBForecastCache/`) is a separate target, not imported by the CLI — skip this section unless you're working on it directly. Its test suite talks to a real DynamoDB API surface via [LocalStack](https://www.localstack.io), never a mock, and is gated behind an environment variable so it never runs as part of plain `swift test`.

```bash
# Start LocalStack (skip if you already have an instance running on :4566 — reuse it)
docker compose -f docker/docker-compose.localstack.yml up -d

# Create the forecast-cache table with TTL enabled
docker/localstack-init.sh

# Run the gated integration suite
MERIDIAN_LOCALSTACK_TESTS=1 swift test --filter DynamoDBForecastCacheTests
```

Expect 4 passing tests, exercising a full `WeatherResult` round-trip through DynamoDB's `GetItem`/`PutItem`, confirming the `ttl` attribute is set correctly, and confirming an expired-but-undeleted item is treated as a miss (DynamoDB's TTL sweep is lazy, so the adapter enforces expiry on read). `docker/localstack-init.sh` is idempotent — safe to re-run against an existing table.

`docker-compose.localstack.yml` binds LocalStack to port `4566`. If that port is already taken by another LocalStack instance (common if you run it persistently for other projects), the `up -d` command will fail to bind — that's fine, just reuse the existing instance and skip straight to `docker/localstack-init.sh` against it.

### Optional: the backend API (AWS Lambda, staged on LocalStack)

The `/v1/forecast` endpoint — the frozen v1 wire contract — is implemented by the
`MeridianLambda` targets and deployed as a SAM stack (`template.yaml`): an API Gateway
**REST API** gated by an API key + usage plan, a `provided.al2023` Swift Lambda, and the
DynamoDB forecast-cache table with native TTL. To build and deploy it locally:

```bash
./scripts/build-lambda.sh     # Docker cross-compile (swift:amazonlinux2023) → bootstrap zip

export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
samlocal deploy --stack-name meridian --resolve-s3 --capabilities CAPABILITY_IAM \
  --no-confirm-changeset --no-fail-on-empty-changeset

# Grab the API id + key from the stack, then:
curl -H "x-api-key: <key>" \
  "http://localhost:4566/restapis/<apiId>/prod/_user_request_/v1/forecast?latitude=52.37&longitude=4.53&activity=swimming"
```

Requests with coordinates above 2 decimal places are rejected with `400
COORDINATE_TOO_PRECISE` by design — clients must round on-device so precise locations
never appear in gateway logs. Requests without `x-api-key` get a 403 from API Gateway
before the handler runs.

### IDE note (Cursor / CLion / VS Code with SourceKit-LSP)

After any `Package.swift` change (new dependency, new target, version bump), `sourcekit-lsp` can hold on to a stale in-memory package graph and show phantom import/symbol errors on code that builds and tests cleanly from the terminal. If that happens: restart the language server (kill the `sourcekit-lsp` process and let the editor respawn it, or Command Palette → "Developer: Reload Window"). This is an editor-index staleness issue, not a real compile error — always trust `swift build`/`swift test` output over IDE squiggles when the two disagree.

---

## Architecture

Six targets in a single Swift package:

```
Sources/
  Core/                    — models, services, rule engine, activity conditions, forecast cache
  Presentation/            — WeatherPresenter, verdict formatting
  App/                     — CLI entry point (ArgumentParser)
  DynamoDBForecastCache/   — DynamoDB-backed ForecastCache adapter (not imported by App)
  MeridianLambdaCore/      — the API's testable pipeline: request validation, v1 wire types, query → Core → JSON
  MeridianLambda/          — thin Lambda runtime shim (API Gateway v1 proxy event in, contract JSON out)
Tests/
  CoreTests/               — rule boundary tests, service layer, model behavior
  PresentationTests/
  MeridianLambdaTests/     — contract-shape, error-code, and precision-boundary tests (no Lambda runtime needed)
  DynamoDBForecastCacheTests/  — gated behind MERIDIAN_LOCALSTACK_TESTS=1, needs LocalStack
```

`Core` has no UI or framework dependencies and imports cleanly into any target — CLI today, the Lambda handler now, iOS next — without modification. `Presentation` depends only on `Core`. The `App` target wires them together. `DynamoDBForecastCache` depends only on `Core` (via the `ForecastCache` protocol) — `Core` itself never gains an AWS dependency. `MeridianLambdaCore` is the only module that knows the v1 wire shape (the same boundary rule the DTOs apply to Open-Meteo's JSON), and `MeridianLambda` is the only module that sees API Gateway/AWS runtime types.

---

## How it works

`ForecastCoordinator` fetches multiple locations concurrently via `withTaskGroup`, checking a `ForecastCache` first and writing back on a miss. `fetch(locations:)` returns one `Result` per input location, in input order — a failed upstream fetch stays visible to the caller (the CLI prints it; an API handler can map it to a 5xx) instead of being silently dropped. The single-location `forecast(for:)` throws directly and is the shape a Lambda handler will call. The default cache is an in-memory, actor-based TTL cache (`InMemoryForecastCache`) — right for a long-lived process like the CLI or iOS app. A `DynamoDBForecastCache` implementation of the same protocol exists for a stateless deployment target like Lambda, where separate execution environments can't share memory; swapping one for the other requires no change to `ForecastCoordinator`. The cache key is derived from rounded coordinates (`Coordinate`), not from a per-request identifier, so repeated queries for the same beach actually hit the cache.

Each `WeatherResult` is then handed to the activity-specific conditions type. `SwimmingConditions` runs two passes over a registered rule list:

1. **Hard guards** — evaluated first; the first match short-circuits everything. Currently: `ThunderstormRule`.
2. **Scoring rules** — all run; `noGo` and `caution` reasons accumulate independently. Currently: `WaterTemperatureRule`, `UVIndexRule`, `WindSpeedRule`, `WaveHeightRule`.

Adding a new check means writing one `SwimmingRule` conformance and appending it to the registry — no changes to the aggregator. `DivingConditions` and `SurfingConditions` will follow the same pattern.

---

## Data

All data comes from [Open-Meteo](https://open-meteo.com) — no API key, no rate limit concerns, no cost.

| Variable | Source |
|---|---|
| Air temperature, wind, UV, weather code | Open-Meteo Weather API (ECMWF IFS, 9 km) |
| Sea surface temperature, wave height, wave period | Open-Meteo Marine API (ECMWF WAM, ICON Wave, Copernicus Marine) |

ECMWF became open data in October 2025; Open-Meteo now provides the full IFS forecast at native 9 km resolution, which is the same model used by professional marine forecasting services.

Coordinates are validated and rounded to two decimal places (~1 km precision) at a single point — the `Coordinate` value object, constructed at the edge (CLI arguments today, request parameters tomorrow) — so no higher-precision location ever reaches a cache key, an outbound API call, or a log line. Every `WeatherResult` carries a `fetchedAt` timestamp that survives cache round-trips, so consumers can always tell how old the underlying forecast is.

---

## Testing

214 tests, test-driven throughout. Tests cover rule boundary conditions (exact threshold values for temperature, UV, wind, and wave height), verdict aggregation logic, `ForecastCoordinator` concurrent fetch, failure-surfacing, and cache behavior, coordinate rounding/validation boundaries, value-object decode validation, and `WeatherPresenter` output formatting. Protocol-based service abstractions (`WeatherService`, `MarineService`, `ForecastCache`) mean all rule, coordinator, and cache tests run against stubs with no network or infrastructure dependency. A separate `DynamoDBForecastCacheTests` suite (4 tests) exercises the real DynamoDB adapter against a LocalStack container — gated behind `MERIDIAN_LOCALSTACK_TESTS=1` so plain `swift test` never requires Docker; see `docker/`.

---

## Status and roadmap

| Feature | Status |
|---|---|
| Swimming verdict (5 rules) | ✅ Done |
| Wave height model | ✅ Done |
| ForecastCoordinator (concurrent multi-location fetch) | ✅ Done |
| CLI (`swift run App <lat> <lon>`) | ✅ Done |
| Forecast caching (in-memory + DynamoDB-backed, swappable) | ✅ Done |
| Hourly forecast (7-day, marine + weather) | 🔨 Next |
| LocationComparer (rank beaches by verdict) | 🔨 Next |
| Diving conditions | Planned |
| Wave period model (surfing) | Planned |
| Backend API (AWS Lambda + API Gateway, key-gated `/v1/forecast`) | ✅ Done — verified on LocalStack; production deploy pending CI |
| iOS app | Planned |

The iOS app will use `Core` and `Presentation` unchanged. Saved locations sync via `NSPersistentCloudKitContainer` (iCloud, no backend required). Condition alerts use `BGAppRefreshTask` and local notifications. No user accounts.

---

## Design notes

**Backend direction.** Meridian's backend API (AWS Lambda + API Gateway, developed and staged against LocalStack) is implemented: `GET /v1/forecast` behind an API key, returning the verdict, reasons, raw metric measurements, the rounded coordinate actually used, and a `fetchedAt` timestamp. The wire contract is frozen at `/v1` — additive changes only; breaking changes require `/v2`. The handler is a thin adapter exactly like `App`: zero business logic, and `Core` needed zero changes to gain it. Coordinates with more than 2 decimal places are rejected (400) rather than re-rounded, so client-side privacy rounding is contractual, not optional.

**Swift 6 / strict concurrency.** All public types conform to `Sendable`. `ForecastCoordinator` stays a plain `struct` — the mutable TTL cache state lives in whichever `ForecastCache` is injected (`InMemoryForecastCache` is itself an `actor`), not in the coordinator, which is what makes the cache backend swappable per deployment target without touching the coordinator.

**Extensibility.** The `Activity` enum (`swimming`, `diving`, `surfing`) and `ActivityConditions` protocol are in place. Each activity owns its rule registry. New rules are one file and one line of registration.

**Coordinates.** `Coordinate` is the single point where privacy rounding and range validation happen — at construction, throwing `CoordinateError` on out-of-range or non-finite input (request input, not a programming bug, so no trap). Services and cache keys accept only `Coordinate`, so nothing downstream can carry unrounded values, and its fixed two-decimal canonical strings are the only coordinate form used in outbound URLs and DynamoDB partition keys. `Location` is a name plus a `Coordinate` and deliberately has no identity of its own — an earlier design minted a `UUID` per instance, which broke cache keying (see the regression test in `ForecastCoordinatorTests`).

**Validated construction.** Value objects with a non-trivial `internal init` (`AirTemperature`, `WaterTemperature`, `WaveHeight`, `UVIndex`, `WindSpeed`, `WeatherCode`) validate against physically-grounded bounds (e.g. no temperature below absolute zero, no negative wave height) on *every* construction path — the normal `internal init` (`preconditionFailure`s on violation; trusted, in-module callers only) and a manual `Decodable` conformance (throws `DecodingError` on violation; for data crossing a serialization boundary, such as a cache round-trip). Both paths matter: `Codable` conformance synthesizes at the type's own `public` access level regardless of the stored property's privacy, so without the manual `Decodable` half, any module could construct an invalid value straight from JSON and bypass `internal init` entirely.
