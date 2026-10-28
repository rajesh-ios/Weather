//
//  Strings+Errors.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

extension Strings {
    /** Error titles (`.title`) and the follow-up hint shown under them (`.suggestion`). */
    enum Errors {
        // MARK: Titles

        static var emptyQuery: String {
            String(localized: "error.emptyQuery.title", defaultValue: "Enter a city name to search.", comment: "Error: search submitted with no text")
        }

        static var cityNotFound: String {
            String(localized: "error.cityNotFound.title", defaultValue: "We couldn't find that city.", comment: "Error: city search had no match")
        }

        static func cityNotFound(_ query: String) -> String {
            String(localized: "error.cityNotFoundNamed.title", defaultValue: "We couldn't find “\(query)”.", comment: "Error: city search had no match; the argument is what the user typed")
        }

        static var missingAPIKey: String {
            String(localized: "error.missingAPIKey.title", defaultValue: "The weather service isn't configured.", comment: "Error: app built without an API key")
        }

        static var invalidAPIKey: String {
            String(localized: "error.invalidAPIKey.title", defaultValue: "The weather service rejected our request.", comment: "Error: API key refused by the server")
        }

        static var rateLimited: String {
            String(localized: "error.rateLimited.title", defaultValue: "Too many requests right now.", comment: "Error: server rate limit reached")
        }

        static var serverError: String {
            String(localized: "error.serverError.title", defaultValue: "The weather service is having trouble.", comment: "Error: server returned a 5xx status")
        }

        static var offline: String {
            String(localized: "error.offline.title", defaultValue: "You appear to be offline.", comment: "Error: no internet connection")
        }

        static var cannotConnect: String {
            String(localized: "error.cannotConnect.title", defaultValue: "We couldn't reach the weather service.", comment: "Error: online, but the server couldn't be reached")
        }

        static var timeout: String {
            String(localized: "error.timeout.title", defaultValue: "The request took too long.", comment: "Error: request timed out")
        }

        static var unexpectedData: String {
            String(localized: "error.unexpectedData.title", defaultValue: "We received unexpected weather data.", comment: "Error: response couldn't be read")
        }

        static var locationDenied: String {
            String(localized: "error.locationDenied.title", defaultValue: "Location access is turned off.", comment: "Error: user denied location permission")
        }

        static var locationUnavailable: String {
            String(localized: "error.locationUnavailable.title", defaultValue: "We couldn't determine your location.", comment: "Error: location lookup failed")
        }

        static var unknown: String {
            String(localized: "error.unknown.title", defaultValue: "Something went wrong.", comment: "Error: anything not covered by a more specific message")
        }

        // MARK: Suggestions

        static var searchExampleSuggestion: String {
            String(localized: "error.suggestion.searchExample", defaultValue: "Try a city such as “Austin”, “Austin, TX” or “Paris, FR”.", comment: "Hint under a search error")
        }

        static var checkAPIKeySuggestion: String {
            String(localized: "error.suggestion.checkAPIKey", defaultValue: "Check the API key in Config/Secrets.xcconfig.", comment: "Hint under an API key error (developer-facing; the path is a file name, don't translate it)")
        }

        static var waitAndRetrySuggestion: String {
            String(localized: "error.suggestion.waitAndRetry", defaultValue: "Please wait a minute and try again.", comment: "Hint under a rate-limit error")
        }

        static var checkConnectionSuggestion: String {
            String(localized: "error.suggestion.checkConnection", defaultValue: "Check your internet connection and try again.", comment: "Hint under a connectivity error")
        }

        static var allowLocationSuggestion: String {
            String(localized: "error.suggestion.allowLocation", defaultValue: "Allow location access in Settings, or search for a city.", comment: "Hint under the location-denied error")
        }

        static var tryAgainSuggestion: String {
            String(localized: "error.suggestion.tryAgain", defaultValue: "Please try again.", comment: "Generic hint under a transient error")
        }
    }
}
