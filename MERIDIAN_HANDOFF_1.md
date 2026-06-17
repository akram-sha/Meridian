# Meridian — Session Handoff

## Repository
**https://github.com/akram-sha/Meridian**
Swift 6.1 · Swift Package Manager · CLion on Windows + WSL (Ubuntu 24.04)
Account: `akram-sha` — commits authored with Apple private relay email `sw76zpz27p@privaterelay.appleid.com`

---

## What Meridian Is

A Swift command-line app that fetches live weather data and evaluates whether
conditions are safe for open water swimming at a given location. The goal is to
eventually compare multiple locations and surface the best spot to swim.

The data source is **Open-Meteo** — a free, no-API-key public weather API.
Current endpoint in use:

```
GET https://api.open-meteo.com/v1/forecast
  ?latitude={lat}
  &longitude={lon}
  &current=temperature_2m,uv_index,wind_speed_10m
```

---

## Project Structure

```
Meridian/
├── Package.swift                         ← swift-tools-version: 6.1
├── Sources/
│   ├── App/
│   │   ├── main.swift                    ← entry point, calls OpenMeteoService
│   │   └── WeatherPresenter.swift        ← formats WeatherResult for terminal output
│   └── Core/
│       ├── Activity/
│       │   ├── Activity.swift            ← enum: .swimming, .diving (todo), .surfing (todo)
│       │   ├── ActivityConditions.swift  ← protocol: verdict + activity
│       │   ├── SwimmingConditions.swift  ← evaluates temp + UV + wind into a Verdict
│       │   └── Verdict.swift            ← enum: .go | .caution(reasons) | .noGo(reasons)
│       ├── DTOs/
│       │   └── OpenMeteoResponse.swift   ← internal Decodable mirror of API JSON
│       ├── Models/
│       │   ├── Temperature.swift         ← celsius storage, C/F/K conversions, OWSSafety
│       │   ├── UVIndex.swift             ← raw value, Severity enum (low→extreme)
│       │   ├── WeatherResult.swift       ← holds Temperature + UVIndex + WindSpeed
│       │   └── WindSpeed.swift           ← kmh storage, knots/mph/ms conversions, SwimmingSafety
│       └── Services/
│           ├── OpenMeteoService.swift    ← live URLSession network call
│           ├── StubWeatherService.swift  ← hardcoded fixture for development
│           └── WeatherService.swift      ← protocol: fetch(latitude:longitude:) async throws
└── Tests/
    ├── AppTests/
    │   ├── AppTests.swift                ← placeholder
    │   └── WeatherPresenterTests.swift   ← 4 tests, uses init() as @BeforeEach
    └── CoreTests/
        ├── Models/
        │   ├── TemperatureTests.swift    ← 6 tests: conversions + known values
        │   ├── UVIndexTests.swift        ← 7 tests: severity boundaries
        │   └── WindSpeedTests.swift      ← 11 tests: conversions + safety boundaries
        └── SwimmingConditionsTests.swift ← 6 tests: verdict evaluation logic
```

**Total: 28 passing tests** as of last commit.

---

## Architecture Decisions Made

### Privacy by design — internal init
All domain types (`Temperature`, `UVIndex`, `WindSpeed`, `WeatherResult`,
`SwimmingConditions`) have `internal init`. The App target can read values but
cannot construct them arbitrarily. Only Core can create instances, and only via
the service layer. `@testable import Core` in tests grants access to internal
inits for fixture construction.

### Single source of truth for units
Each model stores one canonical unit privately and exposes others as computed
properties:
- `Temperature` stores Celsius → exposes `.inCelsius`, `.inFahrenheit`, `.inKelvin`
- `WindSpeed` stores km/h → exposes `.inKmh`, `.inKnots`, `.inMph`, `.inMs`
- `UVIndex` stores raw Double → exposes `.value`

### Safety thresholds
**Temperature (OWSSafety)**
- `.ideal` ≥ 22°C — no wetsuit needed
- `.wetsuitAdvised` 18–21°C
- `.restricted` 16–17°C — below World Aquatics competition minimum
- `.coldShock` 12–15°C — peak cold shock zone
- `.extremeRisk` 11–11.9°C — near British Triathlon hard cutoff
- `.dangerous` < 11°C — guard clause, no OWS recommended

**UVIndex (Severity)** — WHO Clear-sky UV Index scale
- `.low` < 3
- `.moderate` 3–5
- `.high` 6–7
- `.veryHigh` 8–10
- `.extreme` ≥ 11 — guard clause

**WindSpeed (SwimmingSafety)** — Beaufort scale
- `.calm` < 15 km/h
- `.moderate` 15–27 km/h — surface chop
- `.concerning` 28–38 km/h — Force 4–5, organised swims cancelled
- `.dangerous` ≥ 39 km/h — guard clause, Force 6 / Small Craft Advisory

### Activity conditions are generalised, evaluation is specialised
`ActivityConditions` is a protocol with `verdict: Verdict` and `activity: Activity`.
`SwimmingConditions` conforms to it. When diving and surfing are added, they get
their own conditions types with activity-specific thresholds, all conforming to
the same protocol. `WeatherResult` exposes computed vars per activity:

```swift
public var swimmingConditions: SwimmingConditions { ... }
// public var divingConditions: DivingConditions { ... }  // future
```

### DTOs stay internal
`OpenMeteoResponse` is `internal`, never exposed to App. It decodes raw JSON
and converts to `WeatherResult` via `toWeatherResult()`. App only ever sees
domain types, never raw API shapes.

### Linux networking
On Linux, `URLSession` lives in `FoundationNetworking`, not `Foundation`.
The service file uses a conditional import for portability:

```swift
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
```

---

## Current State of Open-Meteo Integration

The live call works end to end. `OpenMeteoService` builds the URL with
`URLComponents`, calls `URLSession.shared.data(from:)`, checks the HTTP status,
decodes via `JSONDecoder`, and maps to `WeatherResult`. The URLSession is
injected via init for future testability.

`main.swift` currently hardcodes Amsterdam coordinates (52.37, 4.90). The
`StubWeatherService` is still in the codebase for development use — swap it
back in `main.swift` to work offline.

---

## What to Verify in Next Session

- Run `swift build && swift test` to confirm all 28 tests still pass
- Run `swift run App` to confirm live API call and verdict output render correctly
- Check emoji rendering in the verdict output (⚠️ was not rendering in WSL terminal
  — this is a terminal font issue, not a code issue)
- Review `WeatherPresenterTests` — the four tests may have redundancy now that
  `SwimmingConditions` is part of the output; consider whether presenter tests
  should also assert on verdict line content

---

## Potential Refactors to Consider

- `SwimmingConditionsTests` uses manual `if case` pattern matching rather than
  a custom `#expect` overload — consider a helper that extracts the verdict case
  cleanly to reduce boilerplate across verdict assertion tests
- `WeatherPresenter` lives in App but has no protocol — if you ever want multiple
  output formats (JSON, CSV for scripting) it should conform to a `Presenter`
  protocol in Core
- The `frmt()` helper is duplicated between `SwimmingConditions` and
  `WeatherPresenter` — could be a shared internal extension on `Double` in Core

---

## Architecture: Moving Forward

### Additional weather variables to fetch from Open-Meteo

All of these are available in the `current` parameter with no extra cost:

| Variable | API key | Relevance |
|----------|---------|-----------|
| Wave height | `wave_height` | Critical for surfing, relevant for swimming |
| Wave period | `wave_period` | Surfing — long period = powerful waves |
| Wave direction | `wave_direction` | Orientation relative to shore |
| Swell height | `swell_wave_height` | Distinguishes swell from wind chop |
| Visibility | `visibility` | Diving safety, fog risk for open water |
| Precipitation | `precipitation` | Lightning risk proxy, water quality proxy |
| Cloud cover | `cloud_cover` | UV modifier — affects actual UV received |
| Relative humidity | `relative_humidity_2m` | Heat index calculation |
| Apparent temperature | `apparent_temperature` | More useful than raw temp for comfort |
| Weathercode | `weather_code` | WMO code — detects storms, thunderstorms |

Add to the DTO's `CodingKeys` and extend `WeatherResult` with new model types
following the same pattern as `WindSpeed`.

### Privacy architecture

Currently there are no privacy concerns — Open-Meteo receives only lat/lon
coordinates, no user identity. To keep it that way as the app grows:

**Location handling**
- Never store coordinates on disk or in any persistent format
- Accept coordinates as command-line arguments, not from a saved profile
- If you ever add a "saved locations" feature, store only place names and resolve
  to coordinates locally using a bundled dataset rather than a geocoding API
  (geocoding APIs log queries and can identify users)
- Consider rounding coordinates to 2 decimal places (~1km precision) before
  sending — sufficient for weather, reduces location specificity

**Networking**
- Open-Meteo is GDPR-compliant and does not require accounts
- All requests are HTTPS — no additional transport work needed
- If you add caching, cache responses keyed by rounded coordinates and timestamp
  only, never by user identity
- Do not add analytics, crash reporting, or any third-party SDK that phones home

**Future API keys**
If you add a service that requires an API key (e.g. a tide API), store it in an
environment variable or a `.env` file excluded from git, never hardcoded.
Add `.env` to `.gitignore` before creating it.

### Multi-location comparison (core goal)

The app's stated purpose is finding the best swimming location. The architecture
for this:

```swift
// In Core
public struct LocationForecast {
    public let name: String
    public let coordinates: (latitude: Double, longitude: Double)
    public let weather: WeatherResult
}

// In Core/Services
public struct LocationComparer {
    public func best(
        among locations: [LocationForecast],
        for activity: Activity
    ) -> LocationForecast? {
        // rank by verdict: .go > .caution > .noGo
        // within .caution, rank by fewest reasons
    }
}
```

`main.swift` would accept a list of named coordinates, fetch all concurrently
with `async let` or `TaskGroup`, then pass to `LocationComparer`.

### Extending to diving and surfing

**Diving** — additional thresholds to add:
- Visibility: < 5m is a noGo for recreational diving
- Current / wave height: relevant but not in Open-Meteo's current variables
- Temperature: different thresholds than swimming (drysuits change the calculus)
- No UV concern underwater

**Surfing** — additional thresholds:
- Wave height: < 0.3m is flat (no surf), > 3m is expert only
- Wave period: < 8s is choppy, > 12s is powerful and well-formed
- Wind direction relative to shore: offshore wind = clean waves (needs bearing data)
- Wind speed: light offshore wind is actually desirable, unlike swimming

Both should follow the `ActivityConditions` protocol pattern already in place.

### Command-line interface

Replace the hardcoded coordinates in `main.swift` with proper argument parsing.
Add `swift-argument-parser` as a dependency:

```swift
// Package.swift
.package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
```

Target shape:
```bash
swift run App --lat 52.37 --lon 4.90 --name "Amsterdam"
swift run App --compare locations.json   # future: compare multiple spots
```

---

## Git State

- Branch: `main`
- Last commit: `test: add SwimmingConditions verdict boundary tests`
- Author: `akram-sha`
- Remote: `https://github.com/akram-sha/Meridian.git`
- Credential helper: `store` (token persisted in `~/.git-credentials`)
