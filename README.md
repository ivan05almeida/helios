# Helios 🌤️

A Ruby on Rails weather forecast application that accepts a location as input,
retrieves forecast data from Open-Meteo, and displays current conditions,
hourly and 7-day forecasts. Results are cached for 30 minutes and a cache
indicator is shown to the user.

## Requirements

- Ruby 3.4.12
- Rails 8.1.4
- Node.js (for asset compilation)

## Running locally

### With Docker

```bash
docker compose up
```

The app will be available at `http://localhost:3000`.

### Without Docker

```bash
bundle install
rails server
```

## Running tests

```bash
bundle exec rspec
```

---

## Architecture

### Service Layer

```
WeathersController
  └── WeatherService                    # orchestrates the forecast pipeline
        └── OpenMeteoAdapter            # delegates to the correct API client
              └── OpenMeteo::WeatherApiService    # HTTP client
                    └── OpenMeteo::ForecastBuilder  # builds value objects
```

The application follows a layered service architecture designed for
extensibility and separation of concerns.

**`WeatherService`** is the entry point for all forecast requests. It
validates coordinates, manages the 30-minute cache via `Rails.cache`, and
delegates the actual API call to the configured adapter. It is adapter-agnostic
— it only knows about `WeatherAdapter`, not any specific provider.

**`WeatherAdapter`** is an abstract base that defines the interface all
adapters must implement: `forecast` and `builder`. New providers (e.g.
OpenWeatherMap, Tomorrow.io) can be added by creating a new adapter without
touching `WeatherService`.

**`OpenMeteoAdapter`** is the concrete adapter for Open-Meteo. It wires the
API service to the forecast builder.

**`OpenMeteo::WeatherApiService`** handles the HTTP communication with the
Open-Meteo API via Faraday. It includes `FaradayConnection` for the shared
connection configuration, and wraps requests in a Stoplight circuit breaker.

**`OpenMeteo::ForecastBuilder`** transforms the raw API JSON response into
strongly typed Ruby value objects (`CurrentWeather`, `HourlyForecast`,
`DailyForecast`, `WeatherForecast`, `WeatherUnits`).

### Value Objects

All forecast data is represented as immutable `Data.define` value objects,
defined in `app/models/weather_forecast.rb`:

- `WeatherForecast` — top-level container
- `CurrentWeather` — current conditions
- `HourlyForecast` — per-hour forecast entry
- `DailyForecast` — per-day forecast entry
- `WeatherUnits` — unit labels returned by the API (°C, mm, km/h)

### Frontend

The UI is built with Hotwire (Turbo + Stimulus) and styled with Tailwind CSS
using [RailsBlocks](https://railsblocks.com) components.

**Turbo Frames** handle page updates without full reloads:
- `geolocation_picker` — the search bar at the top
- `weather_result` — the forecast content area

**Stimulus Controllers:**
- `places_controller.js` — manages the location search input using
  `leaflet-geosearch` with OpenStreetMapProvider (Nominatim). Handles
  debounced search, dropdown rendering, field population, and timezone
  detection via `tz-lookup`.
- `recent_locations_controller.js` — manages the recent locations sidebar
  using `localStorage`. Stores up to 10 locations and re-fetches weather
  immediately on click.

---

## Gem Decisions

### `faraday` + `faraday-retry`
HTTP client for API communication. `faraday-retry` adds automatic retries with
exponential backoff for transient network failures (`ConnectionFailed`,
`TimeoutError`). Retries are disabled in the test environment to keep specs
fast and predictable.

### `stoplight`
Circuit breaker for the Open-Meteo API. After 3 consecutive failures the
circuit opens and subsequent requests fail immediately with a friendly error
message instead of waiting for timeouts. The circuit resets after a 60-second
cool-off period. This protects both the user experience and the upstream
provider from being hammered during an outage.

### `tzinfo` (via Rails)
Used to convert UTC datetimes from the API into the location's local timezone
and the user's selected display timezone. `tz-lookup` on the frontend detects
the IANA timezone from coordinates so the backend receives the correct zone
string without an extra API call.

### `vcr` + `webmock`
VCR records real HTTP interactions as cassettes and replays them in subsequent
test runs, keeping the suite fast and fully offline. WebMock prevents
accidental real network requests during testing. The circuit breaker error
tests mock at the Faraday layer directly to bypass VCR entirely.

### `rspec-rails`
Test framework. The service layer is covered with unit specs using VCR
cassettes for happy-path tests and Faraday mocks for error and circuit breaker
scenarios.

### `rubocop-rails-omakase` + `rubocop-rspec`
Code style enforcement using the Rails team's default configuration with
RSpec-aware cops. Enforces 2-space indentation and consistent Ruby style across
the codebase.

### `simplecov`
Test coverage reporting. Runs automatically with the test suite.

---

## Caching

Forecast results are cached by coordinates (rounded to 2 decimal places) and
adapter name for 30 minutes using `Rails.cache`. Rounding to 2 decimal places
gives approximately 1km of precision — close enough that parallel streets share
the same cache key, since weather conditions don't meaningfully differ at that
scale. This is intentionally more practical than the zip code approach, which
would break for international locations and varies wildly in geographic size.

The `WeathersController` exposes the `cached` boolean from the service result
and displays a badge in the current weather card indicating whether the result
was freshly fetched or served from cache. A "Force refresh" checkbox bypasses
the cache for a single request.

---

## Error Handling

API errors are caught at the service layer and propagated as typed errors:

- `OpenMeteo::ApiError` — base error (connection failures, circuit open)
- `OpenMeteo::ClientError` — 4xx responses (e.g. 429 rate limit)
- `OpenMeteo::ServerError` — 5xx responses


---

## Known Limitations & Next Steps

**No authentication** — recent locations are stored in `localStorage` per
browser session. With user authentication, recent locations could be persisted
to a database and synced across devices.

**Single weather provider** — the adapter pattern is in place to support
multiple providers, but only Open-Meteo is implemented. A provider selector
dropdown would allow users to compare forecasts across sources.

**No database** — the application is stateless by design for this exercise.
Adding `User` and `Location` models would be the natural next step.

**UI** — the current design is functional and clean but uses a neutral palette.
Future improvements could include weather-aware color schemes (warm tones for
sunny days, cool tones for rain) and animated condition icons.
