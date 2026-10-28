//
//  MockWeatherRepository.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
@testable import Weather_App

final class MockWeatherRepository: WeatherRepository {
    var lastSearchedPlace: Place?
    var searchResult: Result<Place, Error> = .success(Place.Mocks.austin)
    var weatherResult: Result<Weather, Error> = .success(Weather.Mocks.austinImperial)
    /// Consumed one per `weather` call to simulate slow requests (e.g. for cancellation tests).
    var weatherDelays: [Duration] = []

    private(set) var searchQueries: [String] = []
    private(set) var weatherRequests: [(Coordinate, TemperatureUnit)] = []
    private(set) var cancelledRequests = 0
    private(set) var savedPlaces: [Place] = []

    func saveLastSearched(_ place: Place) {
        savedPlaces.append(place)
        lastSearchedPlace = place
    }

    func searchCity(_ query: String) async throws -> Place {
        searchQueries.append(query)
        return try searchResult.get()
    }

    func weather(at coordinate: Coordinate, unit: TemperatureUnit) async throws -> Weather {
        weatherRequests.append((coordinate, unit))
        if !weatherDelays.isEmpty {
            do {
                try await Task.sleep(for: weatherDelays.removeFirst())
            } catch {
                cancelledRequests += 1
                throw error
            }
        }
        return try weatherResult.get()
    }
}
