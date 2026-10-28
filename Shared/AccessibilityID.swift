//
//  AccessibilityID.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/**
 Accessibility identifiers, shared by the app and the UI tests.

 This file lives in `Shared/`, which is compiled into **both** the app and the UI-test target,
 so views and tests use the same constants and a typo fails the build instead of a test.
 Identifiers are never shown or read aloud; VoiceOver uses accessibility *labels*.
 */
enum AccessibilityID {
    enum Weather {
        static let searchField = "weather.searchField"
        static let currentLocationButton = "weather.currentLocationButton"
        static let unitToggle = "weather.unitToggle"
        static let emptyState = "weather.emptyState"
        static let loadingIndicator = "weather.loadingIndicator"
        static let locationName = "weather.locationName"
        static let temperature = "weather.temperature"
        static let errorMessage = "weather.errorMessage"
        static let retryButton = "weather.retryButton"
        static let openSettingsButton = "weather.openSettingsButton"
    }

    enum CitySearch {
        static let prompt = "citySearch.prompt"
        static let suggestions = "citySearch.suggestions"
    }
}
