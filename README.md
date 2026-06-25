# Meridian

A Swift package that answers one question for any coastal coordinate: **is it safe to swim here right now?**

Meridian fetches real-time weather and marine data, runs it through a layered rule engine, and returns a structured `Verdict` — `go`, `caution(reasons:)`, or `noGo(reasons:)` — with human-readable explanations for every flag raised. Diving and surfing verdicts are in progress. An iOS app is the end target.

---

## Quick start

```bash
git clone https://github.com/akram-sha/Meridian.git
cd Meridian
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

---

## Architecture

Three targets in a single Swift package:

```
Sources/
  Core/           — models, services, rule engine, activity conditions
  Presentation/   — WeatherPresenter, verdict formatting
  App/            — CLI entry point (ArgumentParser)
Tests/
  CoreTests/      — rule boundary tests, service layer, model behaviour
  PresentationTests/
```

`Core` has no UI or framework dependencies and imports cleanly into any target — CLI today, iOS tomorrow — without modification. `Presentation` depends only on `Core`. The `App` target wires them together.

---

## How it works

`ForecastCoordinator` fetches multiple locations concurrently via `withTaskGroup`, then hands each `WeatherResult` to the activity-specific conditions type.

`SwimmingConditions` runs two passes over a registered rule list:

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

The project is test-driven throughout. Tests cover rule boundary conditions (exact threshold values for temperature, UV, wind, and wave height), verdict aggregation logic, `ForecastCoordinator` concurrent fetch behaviour, and `WeatherPresenter` output formatting. Protocol-based service abstractions (`WeatherService`, `MarineService`) mean all rule and coordinator tests run against stubs with no network dependency.

---

## Status and roadmap

| Feature | Status |
|---|---|
| Swimming verdict (5 rules) | ✅ Done |
| Wave height model | ✅ Done |
| ForecastCoordinator (concurrent multi-location fetch) | ✅ Done |
| CLI (`swift run App <lat> <lon>`) | ✅ Done |
| Hourly forecast (7-day, marine + weather) | 🔨 Next |
| LocationComparer (rank beaches by verdict) | 🔨 Next |
| Diving conditions | Planned |
| Wave period model (surfing) | Planned |
| iOS app | Planned |

The iOS app will use `Core` and `Presentation` unchanged. Saved locations sync via `NSPersistentCloudKitContainer` (iCloud, no backend required). Condition alerts use `BGAppRefreshTask` and local notifications. No user accounts.

---

## Design notes

**Why no backend?** Open-Meteo is free and requires no API key. `ForecastCoordinator` fetches directly from the source. A backend adds infrastructure costs and latency with no data quality benefit — Open-Meteo's marine API runs on ECMWF, the same model commercial services use.

**Swift 6 / strict concurrency.** All public types conform to `Sendable`. `ForecastCoordinator` is a `struct` now and will become an `actor` when a TTL cache is added before the iOS target.

**Extensibility.** The `Activity` enum (`swimming`, `diving`, `surfing`) and `ActivityConditions` protocol are in place. Each activity owns its rule registry. New rules are one file and one line of registration.
