//
//  ModelTests.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/27/26.
//

import Foundation
import Testing
@testable import Weather_App

struct CurrentWeatherDataModelTests {
    @Test func decodesFullResponse() throws {
        let response = CurrentWeatherDataModel.Mocks.austinClearSky

        #expect(response.name == "Austin")
        #expect(response.main.feelsLike == 71.6)
        #expect(response.primaryCondition?.icon == "01d")
        #expect(response.timezone == -18000)
    }

    @Test func toleratesMissingOptionalFields() throws {
        let response = CurrentWeatherDataModel.Mocks.minimal

        #expect(response.weather.isEmpty)
        #expect(response.primaryCondition == nil)
        #expect(response.wind == nil)
        #expect(response.name == "")
    }

    @Test func mapsToDomainModel() throws {
        let weather = Weather.Mocks.austinMetric

        #expect(weather.unit == .metric)
        #expect(weather.stationName == "Austin")
        #expect(weather.conditionDescription == "clear sky")
        #expect(weather.iconCode == "01d")
        #expect(weather.high == 75.2)
        #expect(weather.windSpeed == 8.05)
        #expect(weather.sunrise == Date(timeIntervalSince1970: 1761569400))
        #expect(weather.timeZone?.secondsFromGMT() == -18000)
    }

    @Test func mapsMissingFieldsToNil() throws {
        let weather = Weather.Mocks.minimal

        #expect(weather.iconCode == nil)
        #expect(weather.conditionDescription == "")
        #expect(weather.humidity == nil)
        #expect(weather.sunrise == nil)
        #expect(weather.timeZone == nil)
    }
}

struct WeatherFormatterTests {
    let formatter = WeatherFormatter(locale: Locale(identifier: "en_US"))

    @Test func formatsImperialDisplay() throws {
        let display = formatter.display(for: Weather.Mocks.austinImperial, title: "Austin, Texas")

        #expect(display.locationName == "Austin, Texas")
        #expect(display.temperature == "72°F")
        #expect(display.highLow == "H: 75°  L: 68°")
        #expect(display.condition == "Clear Sky")
        #expect(display.iconURL?.absoluteString == "https://openweathermap.org/img/wn/01d@2x.png")

        let details = Dictionary(uniqueKeysWithValues: display.details.map { ($0.title, $0.value) })
        #expect(details[Strings.Details.humidity] == "40%")
        #expect(details[Strings.Details.wind] == "8 mph")
        #expect(details[Strings.Details.visibility] == "6 mi") // 10 km
        // 1761569400 = 12:50 UTC → 7:50 AM at UTC-5 (city time, not device time)
        #expect(details[Strings.Details.sunrise]?.hasPrefix("7:50") == true) // en_US uses a narrow no-break space before AM
    }

    @Test func formatsMetricUnits() throws {
        let display = formatter.display(for: Weather.Mocks.austinMetric, title: nil)

        #expect(display.temperature == "72°C") // values are as provided by the API, never re-converted
        #expect(display.details.contains { $0.title == Strings.Details.wind && $0.value == "8 m/s" })
        #expect(display.details.contains { $0.title == Strings.Details.visibility && $0.value == "10 km" })
    }

    @Test func fallsBackWhenNamesAreMissing() throws {
        let response = CurrentWeatherDataModel.Mocks.minimal
        let display = formatter.display(for: response.toDomain(unit: .imperial), title: nil)

        #expect(display.locationName == Strings.Weather.currentLocation)
        #expect(display.iconURL == nil)
        #expect(display.details.map(\.title) == [Strings.Details.feelsLike]) // missing fields are skipped
    }

    @Test(arguments: ["", "../evil", "01d?x=1"])
    func rejectsUnsafeIconCodes(code: String) {
        #expect(WeatherFormatter.iconURL(for: code) == nil)
    }
}

struct WeatherErrorTests {
    @Test(arguments: [
        (URLError(.notConnectedToInternet) as Error, WeatherError.offline),
        (URLError(.timedOut), .timeout),
        (URLError(.badServerResponse), .invalidResponse),
        (CocoaError(.fileNoSuchFile), .unknown),
        (WeatherError.rateLimited, .rateLimited),
        (WebServiceError.statusCode(401), .invalidAPIKey),
        (WebServiceError.statusCode(429), .rateLimited),
        (WebServiceError.statusCode(503), .serverError),
        (WebServiceError.statusCode(418), .invalidResponse),
        (WebServiceError.serverResponse, .invalidResponse),
        (URLError(.cannotFindHost), .cannotConnect),
        (URLError(.secureConnectionFailed), .cannotConnect),
    ])
    func mapsUnderlyingErrors(error: Error, expected: WeatherError) {
        #expect(WeatherError(error) == expected)
    }

    @Test func everyErrorHasUserFacingText() {
        let all: [WeatherError] = [
            .emptyQuery, .cityNotFound("X"), .cityNotFound(""), .missingAPIKey, .invalidAPIKey, .rateLimited,
            .serverError, .offline, .cannotConnect, .timeout, .invalidResponse, .decodingFailed,
            .locationDenied, .locationUnavailable, .unknown,
        ]
        for error in all {
            #expect(error.errorDescription?.isEmpty == false)
            #expect(error.recoverySuggestion?.isEmpty == false)
        }
        #expect(WeatherError.cityNotFound("Atlantis").errorDescription?.contains("Atlantis") == true)
    }

    @Test(arguments: [
        (WeatherError.offline, true), (.cannotConnect, true), (.timeout, true), (.serverError, true),
        (.rateLimited, true), (.locationUnavailable, true), (.unknown, true),
        (.emptyQuery, false), (.cityNotFound("X"), false), (.missingAPIKey, false), (.invalidAPIKey, false),
        (.invalidResponse, false), (.decodingFailed, false), (.locationDenied, false),
    ])
    func retryability(error: WeatherError, retryable: Bool) {
        #expect(error.isRetryable == retryable)
    }

    @Test func onlyConnectivityErrorsRecoverOnReconnect() {
        #expect(WeatherError.offline.isConnectivityError)
        #expect(WeatherError.cannotConnect.isConnectivityError)
        #expect(WeatherError.timeout.isConnectivityError)
        #expect(!WeatherError.serverError.isConnectivityError)
        #expect(!WeatherError.cityNotFound("X").isConnectivityError)
    }
}

struct PreferencesStoreTests {
    @Test func roundTripsLastPlaceAndUnit() {
        let store = Fixtures.freshPreferences()
        #expect(store.lastPlace == nil)
        #expect(store.unit == .imperial) // default for US users

        store.lastPlace = Place.Mocks.austin
        store.unit = .metric

        #expect(store.lastPlace == Place.Mocks.austin)
        #expect(store.unit == .metric)
    }

    @Test func corruptDataReadsAsNil() {
        let store = Fixtures.freshPreferences()
        store.defaults.set(Data("not json".utf8), forKey: "lastSearchedPlace")
        store.defaults.set("kelvin", forKey: "temperatureUnit")

        #expect(store.lastPlace == nil)
        #expect(store.unit == .imperial)
    }
}

struct ImageLoaderTests {
    let url = URL(string: "https://openweathermap.org/img/wn/01d@2x.png")!

    @Test func cachesDownloadedImages() async throws {
        let client = MockHTTPClient(data: Fixtures.pngData)
        let loader = ImageLoader(client: client)

        _ = try await loader.image(for: url)
        _ = try await loader.image(for: url)

        #expect(client.requestedURLs.count == 1)
    }

    @Test func invalidImageDataThrows() async {
        let loader = ImageLoader(client: MockHTTPClient(data: Data("not an image".utf8)))
        await #expect(throws: ImageLoader.LoaderError.invalidImageData) { try await loader.image(for: url) }
    }

    @Test func failedDownloadIsNotCached() async throws {
        let client = MockHTTPClient(error: URLError(.timedOut))
        let loader = ImageLoader(client: client)

        await #expect(throws: URLError.self) { try await loader.image(for: url) }
        client.result = .success((Fixtures.pngData, 200))
        _ = try await loader.image(for: url)

        #expect(client.requestedURLs.count == 2)
    }
}
