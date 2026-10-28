//
//  WeatherRepository.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
import OSLog

/**
 Single source of weather data for the presentation layer.
 Hides where data comes from (network, local storage, memory cache) and
 only returns domain models, never data models.
 */
protocol WeatherRepository {
    /**
     Resolve free-text input ("Austin" / "Austin, TX") to a city and remember it as the last searched city.
     */
    func searchCity(_ query: String) async throws -> Place

    /**
     The city to restore on launch, if any.
     */
    var lastSearchedPlace: Place? { get }

    /**
     Remember a city chosen from somewhere other than `searchCity` (e.g. a suggestion).
     */
    func saveLastSearched(_ place: Place)

    /**
     Get current weather for a coordinate, in the given unit system.
     */
    func weather(at coordinate: Coordinate, unit: TemperatureUnit) async throws -> Weather
}

// MARK: - Implementation

final class WeatherRepositoryImpl {
    /**
     OpenWeather refreshes current conditions about every 10 minutes, so an answer
     younger than that is as fresh as a new request. This avoids repeat calls when the user
     flips °F/°C back and forth or re-searches the same city, which helps with
     free-tier rate limits.
     */
    static let cacheLifetime: TimeInterval = 10 * 60

    private struct CacheKey: Hashable {
        let latitude: Double
        let longitude: Double
        let unit: TemperatureUnit
    }

    /** Underlying data stores for API requests. */
    private let weatherDataStore: WeatherDataStore
    private let geocodingDataStore: GeocodingDataStore

    /** Local persistence for the last searched city. */
    private let preferences: PreferencesStore

    /** Injected clock so tests can expire the cache without waiting. */
    private let now: () -> Date

    // Add an LRU limit, or a disk store for offline mode, if that becomes a requirement.
    private var cache: [CacheKey: (weather: Weather, fetchedAt: Date)] = [:]

    init(
        weatherDataStore: WeatherDataStore,
        geocodingDataStore: GeocodingDataStore,
        preferences: PreferencesStore,
        now: @escaping () -> Date = Date.init
    ) {
        self.weatherDataStore = weatherDataStore
        self.geocodingDataStore = geocodingDataStore
        self.preferences = preferences
        self.now = now
    }
}

extension WeatherRepositoryImpl: WeatherRepository {
    var lastSearchedPlace: Place? { preferences.lastPlace }

    func searchCity(_ query: String) async throws -> Place {
        let geocodingQuery = Self.geocodingQuery(for: query)
        guard !geocodingQuery.isEmpty else { throw WeatherError.emptyQuery }

        var results = try await geocodingDataStore.getCities(requestModel: GetCitiesRequestModel(query: geocodingQuery))

        // "Austin, TX" reads as {city},{country} and finds nothing: OpenWeather only accepts a state code
        // as {city},{state},US. So a two-part miss is retried as a US state. Costs one extra call, only on a miss.
        if results.isEmpty, geocodingQuery.filter({ $0 == "," }).count == 1 {
            results = try await geocodingDataStore.getCities(requestModel: GetCitiesRequestModel(query: geocodingQuery + ",US"))
        }

        guard let match = results.first else {
            throw WeatherError.cityNotFound(query)
        }
        let place = match.toDomain()
        // Only successful searches are remembered, so a typo never replaces a good city.
        saveLastSearched(place)
        return place
    }

    func saveLastSearched(_ place: Place) {
        preferences.lastPlace = place
    }

    func weather(at coordinate: Coordinate, unit: TemperatureUnit) async throws -> Weather {
        guard (-90...90).contains(coordinate.latitude), (-180...180).contains(coordinate.longitude) else {
            throw WeatherError.invalidResponse
        }

        let key = CacheKey(latitude: coordinate.latitude, longitude: coordinate.longitude, unit: unit)
        if let entry = cache[key], now().timeIntervalSince(entry.fetchedAt) < Self.cacheLifetime {
            Logger.data.debug("Weather cache hit")
            return entry.weather
        }

        let request = GetCurrentWeatherRequestModel(coordinate: coordinate, unit: unit)
        let weather = try await weatherDataStore.getCurrentWeather(requestModel: request).toDomain(unit: unit)
        cache[key] = (weather, now())
        return weather
    }
}

// MARK: - Helpers

extension WeatherRepositoryImpl {
    /**
     Convert user input into the Geocoding API's `{city},{state},{country}` form by trimming each part.
     "Paris, FR" → "Paris,FR"; "Austin, TX, US" → "Austin,TX,US". Anything after the third part is ignored.
     */
    static func geocodingQuery(for input: String) -> String {
        input
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .prefix(3)
            .joined(separator: ",")
    }
}
