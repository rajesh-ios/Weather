//
//  UITestStubs.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

#if DEBUG
import Foundation

/// Deterministic dependencies for UI tests, enabled by the `-uiTesting` launch argument.
/// This removes network flakiness and the system location prompt from UI tests.
/// Shared stand-ins live in `Support/Stubs/`; the two data-store stubs below are UI-test specific
/// so the real repository still runs underneath.
/// Compiled into Debug builds only, so none of it ships.
enum UITestStubs {
    static let launchArgument = "-uiTesting"

    static func dependencies() -> AppDependencies {
        // Fresh, isolated defaults on every launch so tests don't leak state.
        let suite = "uiTesting"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let preferences = PreferencesStore(defaults: defaults)

        // The real repository on top of stub data stores, so the UI tests also exercise it.
        return AppDependencies(
            weatherRepository: WeatherRepositoryImpl(
                weatherDataStore: StubWeatherDataStore(),
                geocodingDataStore: StubGeocodingDataStore(),
                preferences: preferences
            ),
            locationProvider: StubLocationProvider(), // denied: no system prompt during tests
            citySearch: StubCitySearch(),
            networkMonitor: StubNetworkMonitor(),
            preferences: preferences,
            // Icon downloads fail, so the fallback symbol path is exercised too.
            imageLoader: ImageLoader.Stubs.failing
        )
    }
}

/// Stand-in for OpenWeather geocoding: any name resolves except "Nowhere" (not-found path).
private struct StubGeocodingDataStore: GeocodingDataStore {
    func getCities(requestModel: GetCitiesRequestModel) async throws -> [GeocodingDataModel] {
        let name = requestModel.query.components(separatedBy: ",")[0]
        guard name.caseInsensitiveCompare("Nowhere") != .orderedSame else { return [] }
        return [GeocodingDataModel(name: name, lat: 30.27, lon: -97.74, country: "US", state: "Texas")]
    }
}

/// Stand-in for OpenWeather current weather: 72°F / 22°C clear sky.
private struct StubWeatherDataStore: WeatherDataStore {
    func getCurrentWeather(requestModel: GetCurrentWeatherRequestModel) async throws -> CurrentWeatherDataModel {
        let temp = requestModel.unit == .imperial ? 72 : 22
        let json = """
        {"weather":[{"id":800,"main":"Clear","description":"clear sky","icon":"01d"}],
         "main":{"temp":\(temp),"feels_like":\(temp),"temp_min":\(temp - 5),"temp_max":\(temp + 5),
                 "pressure":1015,"humidity":40},
         "visibility":10000,"wind":{"speed":5},"name":"Austin"}
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(CurrentWeatherDataModel.self, from: Data(json.utf8))
    }
}
#endif
