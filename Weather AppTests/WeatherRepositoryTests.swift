//
//  WeatherRepositoryTests.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
import Testing
@testable import Weather_App

struct WeatherRepositoryTests {
    let weatherDataStore: MockWeatherDataStore
    let geocodingDataStore = MockGeocodingDataStore()
    let preferences: PreferencesStore
    /// Controllable clock: tests move time forward to expire the cache.
    let clock = TestClock()
    let repository: WeatherRepositoryImpl

    final class TestClock {
        var now = Date(timeIntervalSince1970: 1_000_000)
    }

    init() {
        weatherDataStore = MockWeatherDataStore()
        preferences = Fixtures.freshPreferences()
        repository = WeatherRepositoryImpl(
            weatherDataStore: weatherDataStore,
            geocodingDataStore: geocodingDataStore,
            preferences: preferences,
            now: { [clock] in clock.now }
        )
    }

    // MARK: - Search & persistence

    @Test(arguments: [
        ("Austin", "Austin"),
        ("Paris, FR", "Paris,FR"),
        ("  San Francisco ,  CA , US ", "San Francisco,CA,US"),
        ("Austin, TX, US, extra", "Austin,TX,US"),
        (",,", ""),
        ("", ""),
    ])
    func geocodingQuery(input: String, expected: String) {
        #expect(WeatherRepositoryImpl.geocodingQuery(for: input) == expected)
    }

    @Test func searchSendsQueryAndRemembersCity() async throws {
        let place = try await repository.searchCity("Austin, TX, US")

        #expect(geocodingDataStore.getCitiesCalls == [GetCitiesRequestModel.Mocks.austinTexas])
        #expect(place == Place.Mocks.austin)
        #expect(repository.lastSearchedPlace == Place.Mocks.austin)
        #expect(preferences.lastPlace == Place.Mocks.austin) // survives relaunch
    }

    @Test func searchAcceptsNonUSCity() async throws {
        geocodingDataStore.getCitiesResult = .success([GeocodingDataModel.Mocks.paris, GeocodingDataModel.Mocks.austin])

        let place = try await repository.searchCity("Paris")

        #expect(place.name == "Paris")
    }

    @Test func twoPartMissIsRetriedAsUSState() async {
        geocodingDataStore.getCitiesResult = .success([])

        await #expect(throws: WeatherError.cityNotFound("Atlantis, ZZ")) { try await repository.searchCity("Atlantis, ZZ") }
        #expect(geocodingDataStore.getCitiesCalls.map(\.query) == ["Atlantis,ZZ", "Atlantis,ZZ,US"])
    }

    @Test func blankSearchFailsWithoutCallingDataStore() async {
        await #expect(throws: WeatherError.emptyQuery) { try await repository.searchCity(" , ") }
        #expect(geocodingDataStore.getCitiesCalls.isEmpty)
    }

    @Test func failedSearchKeepsPreviousCity() async {
        preferences.lastPlace = Place.Mocks.austin
        geocodingDataStore.getCitiesResult = .success([])

        await #expect(throws: WeatherError.cityNotFound("Atlantis")) { try await repository.searchCity("Atlantis") }
        #expect(repository.lastSearchedPlace == Place.Mocks.austin)
    }

    @Test func savedPlaceIsPersisted() {
        repository.saveLastSearched(Place.Mocks.austin)
        #expect(preferences.lastPlace == Place.Mocks.austin)
    }

    // MARK: - Weather & cache

    @Test func returnsDomainModelInRequestedUnit() async throws {
        let weather = try await repository.weather(at: Coordinate.Mocks.austin, unit: .metric)

        #expect(weather.unit == .metric)
        #expect(weather.stationName == "Austin")
        let call = try #require(weatherDataStore.getCurrentWeatherCalls.first)
        #expect(call.coordinate == Coordinate.Mocks.austin)
        #expect(call.unit == .metric)
    }

    @Test func outOfRangeCoordinateIsRejected() async {
        await #expect(throws: WeatherError.invalidResponse) {
            try await repository.weather(at: Coordinate.Mocks.outOfRange, unit: .imperial)
        }
        #expect(weatherDataStore.getCurrentWeatherCalls.isEmpty)
    }

    @Test func freshResultIsServedFromCache() async throws {
        _ = try await repository.weather(at: Coordinate.Mocks.austin, unit: .imperial)
        clock.now += WeatherRepositoryImpl.cacheLifetime - 1

        _ = try await repository.weather(at: Coordinate.Mocks.austin, unit: .imperial)

        #expect(weatherDataStore.getCurrentWeatherCalls.count == 1)
    }

    @Test func expiredResultIsRefetched() async throws {
        _ = try await repository.weather(at: Coordinate.Mocks.austin, unit: .imperial)
        clock.now += WeatherRepositoryImpl.cacheLifetime

        _ = try await repository.weather(at: Coordinate.Mocks.austin, unit: .imperial)

        #expect(weatherDataStore.getCurrentWeatherCalls.count == 2)
    }

    @Test func cacheIsKeyedByUnitAndPlace() async throws {
        let other = Coordinate.Mocks.newYork

        _ = try await repository.weather(at: Coordinate.Mocks.austin, unit: .imperial)
        _ = try await repository.weather(at: Coordinate.Mocks.austin, unit: .metric)
        _ = try await repository.weather(at: other, unit: .imperial)
        _ = try await repository.weather(at: Coordinate.Mocks.austin, unit: .imperial) // cached

        #expect(weatherDataStore.getCurrentWeatherCalls.count == 3)
    }

    @Test func failuresAreNotCached() async throws {
        weatherDataStore.getCurrentWeatherResult = .failure(URLError(.timedOut))
        await #expect(throws: URLError.self) {
            try await repository.weather(at: Coordinate.Mocks.austin, unit: .imperial)
        }

        weatherDataStore.getCurrentWeatherResult = .success(CurrentWeatherDataModel.Mocks.austinClearSky)
        _ = try await repository.weather(at: Coordinate.Mocks.austin, unit: .imperial)

        #expect(weatherDataStore.getCurrentWeatherCalls.count == 2)
    }
}
