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

Expect a clean build and **130 passing tests**, no network or Docker access required — every `WeatherService`/`MarineService`/`ForecastCache` test runs against an in-module stub.

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

Expect 3 passing tests, exercising a full `WeatherResult` round-trip through DynamoDB's `GetItem`/`PutItem` and confirming the `ttl` attribute is set correctly. `docker/localstack-init.sh` is idempotent — safe to re-run against an existing table.

`docker-compose.localstack.yml` binds LocalStack to port `4566`. If that port is already taken by another LocalStack instance (common if you run it persistently for other projects), the `up -d` command will fail to bind — that's fine, just reuse the existing instance and skip straight to `docker/localstack-init.sh` against it.

### IDE note (Cursor / CLion / VS Code with SourceKit-LSP)

After any `Package.swift` change (new dependency, new target, version bump), `sourcekit-lsp` can hold on to a stale in-memory package graph and show phantom import/symbol errors on code that builds and tests cleanly from the terminal. If that happens: restart the language server (kill the `sourcekit-lsp` process and let the editor respawn it, or Command Palette → "Developer: Reload Window"). This is an editor-index staleness issue, not a real compile error — always trust `swift build`/`swift test` output over IDE squiggles when the two disagree.

---

## Architecture

Four targets in a single Swift package:

```
Sources/
  Core/                    — models, services, rule engine, activity conditions, forecast cache
  Presentation/            — WeatherPresenter, verdict formatting
  App/                     — CLI entry point (ArgumentParser)
  DynamoDBForecastCache/   — DynamoDB-backed ForecastCache adapter (not imported by App)
Tests/
  CoreTests/               — rule boundary tests, service layer, model behavior
  PresentationTests/
  DynamoDBForecastCacheTests/  — gated behind MERIDIAN_LOCALSTACK_TESTS=1, needs LocalStack
```

`Core` has no UI or framework dependencies and imports cleanly into any target — CLI today, iOS and a Lambda handler tomorrow — without modification. `Presentation` depends only on `Core`. The `App` target wires them together. `DynamoDBForecastCache` also depends only on `Core` (via the `ForecastCache` protocol) and exists to be imported by a future Lambda handler target — `Core` itself never gains an AWS dependency.

---

## How it works

`ForecastCoordinator` fetches multiple locations concurrently via `withTaskGroup`, checking a `ForecastCache` first and writing back on a miss. The default cache is an in-memory, actor-based TTL cache (`InMemoryForecastCache`) — right for a long-lived process like the CLI or iOS app. A `DynamoDBForecastCache` implementation of the same protocol exists for a stateless deployment target like Lambda, where separate execution environments can't share memory; swapping one for the other requires no change to `ForecastCoordinator`. The cache key is derived from rounded coordinates, not from a per-request identifier, so repeated queries for the same beach actually hit the cache.

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

Coordinates are rounded to two decimal places (~1 km precision) before any API call to avoid sending precise user locations to a third-party service.

---

## Testing

130 tests, test-driven throughout. Tests cover rule boundary conditions (exact threshold values for temperature, UV, wind, and wave height), verdict aggregation logic, `ForecastCoordinator` concurrent fetch and cache behavior, value-object decode validation, and `WeatherPresenter` output formatting. Protocol-based service abstractions (`WeatherService`, `MarineService`, `ForecastCache`) mean all rule, coordinator, and cache tests run against stubs with no network or infrastructure dependency. A separate `DynamoDBForecastCacheTests` suite (3 tests) exercises the real DynamoDB adapter against a LocalStack container — gated behind `MERIDIAN_LOCALSTACK_TESTS=1` so plain `swift test` never requires Docker; see `docker/`.

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
| Backend API (AWS Lambda + API Gateway) | Planned |
| iOS app | Planned |

The iOS app will use `Core` and `Presentation` unchanged. Saved locations sync via `NSPersistentCloudKitContainer` (iCloud, no backend required). Condition alerts use `BGAppRefreshTask` and local notifications. No user accounts.

---

## Design notes

**Backend direction.** Meridian is moving from a standalone CLI to a backend API service (AWS Lambda + API Gateway, developed and staged against LocalStack) that a future iOS app will call. `Core` and `Presentation` are unchanged by this — a Lambda handler is a fourth thin adapter target, exactly like `App` today, with zero business logic of its own. See `misc/` for the current backend planning notes.

**Swift 6 / strict concurrency.** All public types conform to `Sendable`. `ForecastCoordinator` stays a plain `struct` — the mutable TTL cache state lives in whichever `ForecastCache` is injected (`InMemoryForecastCache` is itself an `actor`), not in the coordinator, which is what makes the cache backend swappable per deployment target without touching the coordinator.

**Extensibility.** The `Activity` enum (`swimming`, `diving`, `surfing`) and `ActivityConditions` protocol are in place. Each activity owns its rule registry. New rules are one file and one line of registration.

**Validated construction.** Value objects with a non-trivial `internal init` (`AirTemperature`, `WaterTemperature`, `WaveHeight`, `UVIndex`, `WindSpeed`, `WeatherCode`) validate against physically-grounded bounds (e.g. no temperature below absolute zero, no negative wave height) on *every* construction path — the normal `internal init` (`preconditionFailure`s on violation; trusted, in-module callers only) and a manual `Decodable` conformance (throws `DecodingError` on violation; for data crossing a serialization boundary, such as a cache round-trip). Both paths matter: `Codable` conformance synthesizes at the type's own `public` access level regardless of the stored property's privacy, so without the manual `Decodable` half, any module could construct an invalid value straight from JSON and bypass `internal init` entirely.
