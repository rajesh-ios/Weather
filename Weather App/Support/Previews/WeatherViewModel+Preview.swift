//
//  WeatherViewModel+Preview.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import Foundation

extension WeatherViewModel {
    /// A view model wired to stubs, for SwiftUI previews.
    /// - Parameters:
    ///   - behavior: How the repository answers searches and weather requests.
    ///   - location: Location permission and answer.
    ///   - lastSearchedPlace: Shown on `start()`, like a relaunch.
    ///   - unit: Starting °F/°C choice.
    static func preview(
        _ behavior: StubBehavior<Weather> = .success(Weather.Mocks.austinImperial),
        location: StubLocationProvider = StubLocationProvider(),
        lastSearchedPlace: Place? = nil,
        unit: TemperatureUnit = .imperial
    ) -> WeatherViewModel {
        let suite = "preview.\(UUID().uuidString)"
        let preferences = PreferencesStore(defaults: UserDefaults(suiteName: suite) ?? .standard)
        preferences.unit = unit
        return WeatherViewModel(
            repository: StubWeatherRepository(behavior, lastSearchedPlace: lastSearchedPlace),
            location: location,
            network: StubNetworkMonitor(),
            preferences: preferences
        )
    }
}
#endif
