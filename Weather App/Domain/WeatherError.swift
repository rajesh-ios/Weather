//
//  WeatherError.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import Foundation

/// Every failure the user can see. Low-level errors (URLError, DecodingError, HTTP codes)
/// are mapped here once so the UI only ever deals with friendly, localized messages.
enum WeatherError: Error, Equatable {
    case emptyQuery
    case cityNotFound(String)
    case missingAPIKey
    case invalidAPIKey
    case rateLimited
    case serverError
    case offline
    /// The device is online, but the weather service couldn't be reached (DNS, TLS, host down).
    case cannotConnect
    case timeout
    case invalidResponse
    case decodingFailed
    case locationDenied
    case locationUnavailable
    case unknown

    /// Normalizes any thrown error into a `WeatherError`.
    init(_ error: Error) {
        switch error {
        case let error as WeatherError:
            self = error
        case let error as WebServiceError:
            switch error {
            case .statusCode(let code): self = WeatherError(httpStatus: code)
            case .malformedURL, .serverResponse: self = .invalidResponse
            }
        case let error as URLError:
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                self = .offline
            case .timedOut:
                self = .timeout
            case .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed, .secureConnectionFailed,
                 .internationalRoamingOff, .callIsActive:
                self = .cannotConnect
            default:
                self = .invalidResponse
            }
        case is DecodingError:
            self = .decodingFailed
        default:
            self = .unknown
        }
    }

    /// Maps a non-2xx HTTP status from OpenWeather.
    init(httpStatus: Int, query: String = "") {
        switch httpStatus {
        case 401: self = .invalidAPIKey
        case 404: self = .cityNotFound(query)
        case 429: self = .rateLimited
        case 500...599: self = .serverError
        default: self = .invalidResponse
        }
    }

    /// Whether the fix lives in the Settings app (drives the "Open Settings" button).
    var opensSettings: Bool { self == .locationDenied }

    /// Whether trying the same request again can succeed. Drives the "Try Again" button and
    /// the automatic retry when the app returns to the foreground. Bad input, a bad API key,
    /// or data we can't read will fail the same way every time.
    var isRetryable: Bool {
        switch self {
        case .offline, .cannotConnect, .timeout, .serverError, .rateLimited, .locationUnavailable, .unknown:
            true
        case .emptyQuery, .cityNotFound, .missingAPIKey, .invalidAPIKey, .invalidResponse, .decodingFailed, .locationDenied:
            false
        }
    }

    /// Whether the failure was about connectivity, so it's worth retrying when the connection returns.
    var isConnectivityError: Bool {
        [.offline, .cannotConnect, .timeout].contains(self)
    }
}

extension WeatherError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyQuery: Strings.Errors.emptyQuery
        case .cityNotFound(let query) where query.isEmpty: Strings.Errors.cityNotFound
        case .cityNotFound(let query): Strings.Errors.cityNotFound(query)
        case .missingAPIKey: Strings.Errors.missingAPIKey
        case .invalidAPIKey: Strings.Errors.invalidAPIKey
        case .rateLimited: Strings.Errors.rateLimited
        case .serverError: Strings.Errors.serverError
        case .offline: Strings.Errors.offline
        case .cannotConnect: Strings.Errors.cannotConnect
        case .timeout: Strings.Errors.timeout
        case .invalidResponse, .decodingFailed: Strings.Errors.unexpectedData
        case .locationDenied: Strings.Errors.locationDenied
        case .locationUnavailable: Strings.Errors.locationUnavailable
        case .unknown: Strings.Errors.unknown
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .emptyQuery, .cityNotFound: Strings.Errors.searchExampleSuggestion
        case .missingAPIKey, .invalidAPIKey: Strings.Errors.checkAPIKeySuggestion
        case .rateLimited: Strings.Errors.waitAndRetrySuggestion
        case .offline, .cannotConnect: Strings.Errors.checkConnectionSuggestion
        case .locationDenied: Strings.Errors.allowLocationSuggestion
        case .serverError, .timeout, .invalidResponse, .decodingFailed, .locationUnavailable, .unknown:
            Strings.Errors.tryAgainSuggestion
        }
    }
}
