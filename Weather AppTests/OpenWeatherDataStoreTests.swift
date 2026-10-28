//
//  OpenWeatherDataStoreTests.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
import Testing
@testable import Weather_App

/// The data store against recorded API fixtures (`Fixtures/API/`): it must send the same request
/// the fixture recorded, decode happy responses, and surface unhappy ones as errors.
struct OpenWeatherDataStoreTests {
    private func dataStore(_ fixture: APIFixture) -> (OpenWeatherDataStore, MockHTTPClient) {
        let client = MockHTTPClient(fixture: fixture)
        return (OpenWeatherDataStore(apiKey: "KEY", client: client), client)
    }

    private func query(of url: URL?) -> [String: String] {
        let items = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
        return Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })
    }

    // MARK: - Contract: the app sends what the recorded API call sent

    // Arguments are plain values: test arguments are evaluated off the main actor,
    // so request models (main-actor types in this project) are built inside the test.
    @Test(arguments: [
        ("weather_200_austin_imperial", TemperatureUnit.imperial, "en"),
        ("weather_200_austin_metric_spanish", .metric, "es"),
    ])
    func weatherRequestMatchesRecording(name: String, unit: TemperatureUnit, language: String) async throws {
        let fixture = APIFixture.load(name)
        let (store, client) = dataStore(fixture)
        let requestModel = GetCurrentWeatherRequestModel(coordinate: Coordinate.Mocks.austin, unit: unit, languageCode: language)

        _ = try await store.getCurrentWeather(requestModel: requestModel)

        let sent = try #require(client.requestedURLs.first)
        #expect(sent.path == fixture.requestURL.path)
        #expect(query(of: sent).filter { $0.key != "appid" } == fixture.requestQuery)
        #expect(query(of: sent)["appid"] == "KEY")
    }

    @Test(arguments: [
        ("geocoding_200_austin_tx", "Austin,TX,US"),
        ("geocoding_200_springfield_multiple", "Springfield,US"),
    ])
    func geocodingRequestMatchesRecording(name: String, cityQuery: String) async throws {
        let fixture = APIFixture.load(name)
        let (store, client) = dataStore(fixture)

        _ = try await store.getCities(requestModel: GetCitiesRequestModel(query: cityQuery))

        let sent = try #require(client.requestedURLs.first)
        #expect(sent.path == fixture.requestURL.path)
        #expect(query(of: sent).filter { $0.key != "appid" } == fixture.requestQuery)
    }

    // MARK: - Happy paths decode

    @Test func decodesRecordedImperialWeather() async throws {
        let (store, _) = dataStore(.load("weather_200_austin_imperial"))

        let model = try await store.getCurrentWeather(requestModel: GetCurrentWeatherRequestModel.Mocks.austinImperial)

        #expect(model.name == "Austin")
        #expect(model.main.temp == 66.74)
        #expect(model.primaryCondition?.description == "few clouds")
        #expect(model.primaryCondition?.icon == "02n")
        #expect(model.timezone == -18000)
    }

    @Test func decodesRecordedSpanishCondition() async throws {
        let (store, _) = dataStore(.load("weather_200_austin_metric_spanish"))

        let model = try await store.getCurrentWeather(requestModel: GetCurrentWeatherRequestModel.Mocks.austinMetricSpanish)

        #expect(model.primaryCondition?.description == "algo de nubes")
        #expect(model.main.temp == 19.21)
    }

    @Test func decodesResponseMissingOptionalFields() async throws {
        let (store, _) = dataStore(.load("weather_200_missing_optional_fields"))

        let model = try await store.getCurrentWeather(requestModel: GetCurrentWeatherRequestModel.Mocks.austinImperial)

        #expect(model.weather.isEmpty)
        #expect(model.wind == nil)
        #expect(model.sys == nil)
        #expect(model.name == "")
    }

    @Test func decodesRecordedGeocodingResults() async throws {
        let (austinStore, _) = dataStore(.load("geocoding_200_austin_tx"))
        let austin = try await austinStore.getCities(requestModel: GetCitiesRequestModel.Mocks.austinTexas)
        #expect(austin.map(\.state) == ["Texas"])

        let (springfieldStore, _) = dataStore(.load("geocoding_200_springfield_multiple"))
        let springfields = try await springfieldStore.getCities(requestModel: GetCitiesRequestModel(query: "Springfield,US"))
        #expect(springfields.map(\.state) == ["Illinois", "Massachusetts", "Missouri", "Ohio", "Oregon"])
    }

    // MARK: - Unhappy paths throw

    @Test(arguments: [
        ("weather_400_wrong_latitude", 400),
        ("weather_401_invalid_api_key", 401),
        ("weather_429_rate_limited", 429),
        ("weather_503_service_unavailable", 503), // HTML body: status is checked before decoding
    ])
    func weatherErrorStatusIsThrown(name: String, status: Int) async {
        let (store, _) = dataStore(.load(name))
        await #expect(throws: WebServiceError.statusCode(status)) {
            try await store.getCurrentWeather(requestModel: GetCurrentWeatherRequestModel.Mocks.austinImperial)
        }
    }

    @Test(arguments: [("geocoding_400_empty_query", 400), ("geocoding_401_invalid_api_key", 401)])
    func geocodingErrorStatusIsThrown(name: String, status: Int) async {
        let (store, _) = dataStore(.load(name))
        await #expect(throws: WebServiceError.statusCode(status)) {
            try await store.getCities(requestModel: GetCitiesRequestModel.Mocks.austin)
        }
    }

    @Test func unexpectedShapeThrowsDecodingError() async {
        let (store, _) = dataStore(.load("weather_200_unexpected_shape"))
        await #expect(throws: DecodingError.self) {
            try await store.getCurrentWeather(requestModel: GetCurrentWeatherRequestModel.Mocks.austinImperial)
        }
    }

    // MARK: - Failures before or below HTTP

    @Test func missingAPIKeyFailsBeforeNetwork() async {
        let client = MockHTTPClient(json: "[]")
        let store = OpenWeatherDataStore(apiKey: "", client: client)

        await #expect(throws: WeatherError.missingAPIKey) {
            try await store.getCities(requestModel: GetCitiesRequestModel.Mocks.austin)
        }
        #expect(client.requests.isEmpty)
    }

    @Test func transportErrorsPassThrough() async {
        let store = OpenWeatherDataStore(apiKey: "KEY", client: MockHTTPClient(error: URLError(.notConnectedToInternet)))

        await #expect(throws: URLError.self) {
            try await store.getCities(requestModel: GetCitiesRequestModel.Mocks.austin)
        }
    }
}
