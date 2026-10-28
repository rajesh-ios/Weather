//
//  WeatherRepositoryFixtureTests.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
import Testing
@testable import Weather_App

/// End to end below the view model: fixture → HTTP → data store → repository → domain result,
/// or the user-facing `WeatherError` the screen would show.
struct WeatherRepositoryFixtureTests {
    private func repository(_ fixtureName: String) -> WeatherRepositoryImpl {
        let store = OpenWeatherDataStore(apiKey: "KEY", client: MockHTTPClient(fixture: .load(fixtureName)))
        return WeatherRepositoryImpl(weatherDataStore: store, geocodingDataStore: store, preferences: Fixtures.freshPreferences())
    }

    // MARK: - Happy paths

    @Test func recordedWeatherBecomesDomainModel() async throws {
        let weather = try await repository("weather_200_austin_imperial").weather(at: Coordinate.Mocks.austin, unit: .imperial)

        #expect(weather.unit == .imperial)
        #expect(weather.stationName == "Austin")
        #expect(weather.conditionDescription == "few clouds")
        #expect(weather.iconCode == "02n")
        #expect(weather.timeZone?.secondsFromGMT() == -18000)
    }

    @Test func missingOptionalFieldsBecomeNil() async throws {
        let weather = try await repository("weather_200_missing_optional_fields").weather(at: Coordinate.Mocks.austin, unit: .imperial)

        #expect(weather.iconCode == nil)
        #expect(weather.windSpeed == nil)
        #expect(weather.sunrise == nil)
    }

    @Test func recordedGeocodingResolvesCity() async throws {
        let place = try await repository("geocoding_200_austin_tx").searchCity("Austin, TX, US")

        #expect(place.displayName == "Austin, Texas")
    }

    @Test func ambiguousNamePicksFirstMatch() async throws {
        let place = try await repository("geocoding_200_springfield_multiple").searchCity("Springfield")

        #expect(place.displayName == "Springfield, Illinois")
    }

    @Test func nonUSCityResolves() async throws {
        let place = try await repository("geocoding_200_foreign_only").searchCity("Paris")

        #expect(place.displayName == "Paris, Ile-de-France")
    }

    // MARK: - Unhappy paths: what the user would be told

    @Test(arguments: [
        ("weather_400_wrong_latitude", WeatherError.invalidResponse),
        ("weather_401_invalid_api_key", .invalidAPIKey),
        ("weather_429_rate_limited", .rateLimited),
        ("weather_503_service_unavailable", .serverError),
        ("weather_200_unexpected_shape", .decodingFailed),
    ])
    func weatherFailureMapsToUserError(name: String, expected: WeatherError) async {
        do {
            _ = try await repository(name).weather(at: Coordinate.Mocks.austin, unit: .imperial)
            Issue.record("\(name) should have failed")
        } catch {
            #expect(WeatherError(error) == expected)
        }
    }

    @Test(arguments: [
        ("geocoding_200_no_match", WeatherError.cityNotFound("Qwzxvbnq")),
        ("geocoding_400_empty_query", .invalidResponse),
        ("geocoding_401_invalid_api_key", .invalidAPIKey),
    ])
    func searchFailureMapsToUserError(name: String, expected: WeatherError) async {
        do {
            _ = try await repository(name).searchCity("Qwzxvbnq")
            Issue.record("\(name) should have failed")
        } catch {
            #expect(WeatherError(error) == expected)
        }
    }
}
