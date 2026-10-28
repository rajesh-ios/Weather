//
//  AppDependencies.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import Foundation

/// Composition root: the only place concrete implementations are chosen.
/// Everything downstream receives its dependencies through initializers.
struct AppDependencies {
    let weatherRepository: WeatherRepository
    let locationProvider: LocationProviding
    let citySearch: CitySearching
    let networkMonitor: NetworkMonitoring
    let preferences: PreferencesStore
    let imageLoader: ImageLoader

    /// Picks live or UI-test dependencies based on launch arguments.
    static func make(processInfo: ProcessInfo = .processInfo) -> AppDependencies {
        #if DEBUG
        if processInfo.arguments.contains(UITestStubs.launchArgument) {
            return UITestStubs.dependencies()
        }
        #endif
        return live()
    }

    static func live(bundle: Bundle = .main) -> AppDependencies {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        // URLCache gives icons a disk cache across launches; ImageLoader adds an in-memory layer.
        configuration.urlCache = URLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024)
        let session = URLSession(configuration: configuration)
        let preferences = PreferencesStore(defaults: .standard)

        // API calls retry transient failures; icons use the plain session (they fall back to a symbol).
        let openWeather = OpenWeatherDataStore(apiKey: apiKey(from: bundle), client: RetryingHTTPClient(wrapping: session))

        return AppDependencies(
            weatherRepository: WeatherRepositoryImpl(
                weatherDataStore: openWeather,
                geocodingDataStore: openWeather,
                preferences: preferences
            ),
            locationProvider: LocationService(),
            citySearch: MapKitCitySearchService(),
            networkMonitor: NetworkMonitor(),
            preferences: preferences,
            imageLoader: ImageLoader(client: session)
        )
    }

    /// Reads the key injected from `Config/Secrets.xcconfig` via Info.plist.
    /// An empty/unresolved value is passed through; the data store turns it into a friendly error.
    static func apiKey(from bundle: Bundle) -> String {
        let raw = (bundle.object(forInfoDictionaryKey: "OWMAPIKey") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.hasPrefix("$(") ? "" : raw
    }
}
