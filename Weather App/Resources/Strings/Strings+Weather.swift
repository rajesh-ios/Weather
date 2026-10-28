//
//  Strings+Weather.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

extension Strings {
    /** Weather screen: navigation bar, search bar, empty/loading/error states. */
    enum Weather {
        static var title: String {
            String(localized: "weather.title", defaultValue: "Weather", comment: "Navigation bar title of the main screen")
        }

        static var searchPlaceholder: String {
            String(localized: "weather.search.placeholder", defaultValue: "Search city, e.g. Austin, TX", comment: "Placeholder in the city search bar")
        }

        static var currentLocationButton: String {
            String(localized: "weather.currentLocationButton.accessibilityLabel", defaultValue: "Use current location", comment: "VoiceOver label for the location arrow button")
        }

        static var unitToggle: String {
            String(localized: "weather.unitToggle.accessibilityLabel", defaultValue: "Temperature unit", comment: "VoiceOver label for the °F/°C switch")
        }

        static var emptyTitle: String {
            String(localized: "weather.empty.title", defaultValue: "Search for a City", comment: "Title shown before any weather is loaded")
        }

        static var emptyMessage: String {
            String(localized: "weather.empty.message", defaultValue: "Enter a city above, or tap the location button for weather where you are.", comment: "Hint shown before any weather is loaded")
        }

        static var loading: String {
            String(localized: "weather.loading", defaultValue: "Loading weather…", comment: "Shown while weather is being fetched")
        }

        static var tryAgain: String {
            String(localized: "weather.error.tryAgain", defaultValue: "Try Again", comment: "Button that repeats the failed request")
        }

        static var openSettings: String {
            String(localized: "weather.error.openSettings", defaultValue: "Open Settings", comment: "Button that opens the Settings app to allow location access")
        }

        static var currentLocation: String {
            String(localized: "weather.currentLocation", defaultValue: "Current Location", comment: "Place name when the weather service returns no station name")
        }

        /** "H: 75°  L: 68°" */
        static func highLow(high: String, low: String) -> String {
            String(localized: "weather.highLow", defaultValue: "H: \(high)  L: \(low)", comment: "Today's high and low temperature; both are formatted temperatures such as 75°")
        }
    }
}
