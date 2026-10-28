# Weather App (iOS)

Look up current weather for any city, or for your current location, using the OpenWeather API.

**Author:** Banka Rajesh · rajesh.banka88@gmail.com

## Setup

1. Copy `Config/Secrets.example.xcconfig` → `Config/Secrets.xcconfig` and set `OWM_API_KEY`
   (the real file is gitignored; without it the app shows "The weather service isn't configured").
2. Open `Weather App.xcodeproj` in Xcode 26+, select an iOS 17+ simulator, and run.

## Features

- Type-ahead city list: tapping the search bar opens a suggestion list that filters as you type ("Aus" → Austin TX, Austell GA…) using Apple MapKit autocomplete, which needs no API key. Picking a city closes the list and loads its weather.
- Pressing Search without picking a suggestion falls back to OpenWeather's Geocoding API ("Paris", "Paris, FR", "Austin, TX"; a two-part miss is retried as `City,ST,US` since OpenWeather only takes state codes that way), then fetches weather by lat/lon
  (OpenWeather has deprecated `q=` lookup on `/data/2.5/weather`).
- On launch: shows the last searched city if there is one; asks for location permission; with no saved city and permission granted, shows weather for the current location.
- °F/°C toggle (saved), condition icons with a memory + disk cache, and friendly errors with Retry or Open Settings.
- Portrait and landscape: the layout switches between stacked and side-by-side based on size classes (iPhone landscape, iPad).
- VoiceOver labels and grouping, Dynamic Type, and a String Catalog (English; ready for more languages).

## Architecture — MVVM-C, no third-party libraries, no storyboards

```
App/            AppDelegate, SceneDelegate, AppDependencies (composition root / DI)
Coordinators/   AppCoordinator — builds screens, handles routing (Open Settings, picked city)
Views/          WeatherViewController (UIKit shell, search controller) hosting
                WeatherView + CitySearchView (SwiftUI)
ViewModels/     WeatherViewModel, CitySearchViewModel, WeatherDisplay + WeatherFormatter
Domain/
  Models/       Weather, Place, Coordinate, TemperatureUnit
  Repositories/ WeatherRepository (protocol) + WeatherRepositoryImpl: business rules, persistence, 10-min cache
  WeatherError  user-facing errors
Data/
  DataStores/   OpenWeatherDataStore, adopting WeatherDataStore + GeocodingDataStore (one protocol per API group)
  RequestModels/  GetCurrentWeatherRequestModel, GetCitiesRequestModel
  DataModels/   CurrentWeatherDataModel, GeocodingDataModel (+ toDomain mapping)
  Routes.swift  OpenWeatherRoute paths      Params.swift  type-safe query params
Networking/     Route, Param, Request, DataStore (generic send<Model>), HTTPClient, WebServiceError
Services/       MapKitCitySearchService, LocationService, ImageLoader, PreferencesStore
Resources/      Strings (+ per-feature extensions), SFSymbol names, Localizable.xcstrings
Support/        Logger categories (OSLog), plus Debug-only test and preview support:
                Mocks/ (`Type.Mocks` sample models, shared by tests and previews), Stubs/ (configurable
                stand-ins: success / failure / loading), Previews/, UITestStubs (-uiTesting launch argument)
Shared/         AccessibilityID: compiled into both the app and the UI-test target
```

No user-facing text is written inline in views. It comes from `Strings.<Feature>.<name>`, which uses
semantic dotted keys (`weather.error.tryAgain`), English text as `defaultValue`, and a translator `comment`.
Text lives in `Localizable.xcstrings` (English; add a language there to translate). SF Symbol names come from `SFSymbol`, and
views and UI tests share the same `AccessibilityID` constants.

Data flows View → ViewModel → Repository → DataStore → Request/Route → HTTPClient. Each layer has its own model type: `RequestModel` going in, `DataModel` coming back from the API, and domain `Weather`/`Place` above the repository. Data models never reach the ViewModels. The networking layer follows the pattern used in the team's main iOS codebase: string-literal routes, `Params.<Group>.<Name>` structs, and one data store protocol per API group.

Dependencies are passed in through initializers from `AppDependencies`. Protocols exist only where a test double is needed: `WeatherRepository`, `WeatherDataStore`, `GeocodingDataStore`, `CitySearching`, `HTTPClient`, `LocationProviding`, `WeatherRouting`, `CitySearchRouting`.

When a suggestion is picked, `CitySearchViewModel` tells the coordinator (`CitySearchRouting`), which closes search and asks `WeatherViewModel` to show that city. The two screens never reference each other.

Starting a new search cancels the in-flight one, including its URLSession request. Logs use `OSLog`; filter Console.app on subsystem `com.rajesh.Weather-App`. The API key is never logged.

## Errors, retries and duplicate calls

| Failure | Automatic | User sees |
|---|---|---|
| 502/503/504, dropped connection | Up to 2 retries, 1s then 2s plus random spread (`RetryingHTTPClient`) | Spinner; error only if all 3 attempts fail |
| 429 rate limited | One retry if `Retry-After` ≤ 5s | "Too many requests" + Try Again |
| No internet, can't reach host, timeout | No immediate retry; retried once **when the connection returns** (`NetworkMonitor`) and on return to the foreground | Offline / connection message + Try Again |
| 401, 404, bad data, missing key | Never | Message only (Try Again would fail the same way) |
| Cancelled by a newer request | Never | Nothing; only the newest request updates the screen |

Timeouts aren't retried automatically: each attempt already waits up to 15s, so three attempts would keep the spinner up for about 45 seconds.
Duplicate calls are avoided by cancelling the previous weather request when a new one starts, the repository's 10-minute cache, and sharing in-flight icon downloads (`ImageLoader`).

## Previews

Every view file ends with `#Preview`s covering each state (idle, loading, loaded, each error type) and
layout edge cases (landscape, iPad width, dark mode, largest Dynamic Type, extreme values, long names,
missing data, icon failed/loading). They're wrapped in `#if DEBUG`, so release builds never include them.

## Tests

- **Unit tests** (Swift Testing, `Weather AppTests`): ViewModel flows (including cancellation, reconnect and foreground recovery), the retry policy, the suggestion list (typing, no results, errors, selection), repository rules, persistence and caching, routes and requests, data store requests and error mapping, API-to-domain mapping, formatting, preferences, and the image cache.
- **API fixtures** (`Weather AppTests/Fixtures/API/`): one JSON file per API exchange, holding the request (with `appid` redacted) and the response (status, headers, body), for happy and unhappy paths. "Recorded" fixtures are real OpenWeather responses; "synthetic" ones cover cases the live API can't produce on demand (429, 503, malformed bodies). `MockHTTPClient(fixture: .load("weather_401_invalid_api_key"))` replays one. Tests check that the app sends the recorded request, decodes happy responses, and turns each unhappy one into the right user-facing error.
- **UI tests** (XCTest, `Weather AppUITests`): search, picking a suggestion, not-found error, unit toggle, denied location, and landscape. These run against stubbed services, so they need no network and are deterministic.

Run everything with ⌘U, or:
```
xcodebuild test -project "Weather App.xcodeproj" -scheme "Weather App" \
  -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO
```
