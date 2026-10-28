//
//  PreferencesStore.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import Foundation

/// Persists the last searched city and the unit choice.
/// `UserDefaults` is injected so tests (and UI tests) use an isolated suite.
struct PreferencesStore {
    private enum Key {
        static let lastPlace = "lastSearchedPlace"
        static let unit = "temperatureUnit"
    }

    let defaults: UserDefaults

    var lastPlace: Place? {
        get {
            // Corrupt or outdated data decodes to nil instead of crashing.
            defaults.data(forKey: Key.lastPlace).flatMap { try? JSONDecoder().decode(Place.self, from: $0) }
        }
        nonmutating set {
            defaults.set(newValue.flatMap { try? JSONEncoder().encode($0) }, forKey: Key.lastPlace)
        }
    }

    /// Defaults to °F; the toggle switches to °C.
    var unit: TemperatureUnit {
        get { defaults.string(forKey: Key.unit).flatMap(TemperatureUnit.init(rawValue:)) ?? .imperial }
        nonmutating set { defaults.set(newValue.rawValue, forKey: Key.unit) }
    }
}
