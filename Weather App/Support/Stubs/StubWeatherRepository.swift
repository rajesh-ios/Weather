//
//  StubWeatherRepository.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import Foundation

/// Repository stand-in for previews: every call answers with `behavior`.
final class StubWeatherRepository: WeatherRepository {
    var behavior: StubBehavior<Weather>
    var lastSearchedPlace: Place?

    init(_ behavior: StubBehavior<Weather> = .success(Weather.Mocks.austinImperial), lastSearchedPlace: Place? = nil) {
        self.behavior = behavior
        self.lastSearchedPlace = lastSearchedPlace
    }

    func searchCity(_ query: String) async throws -> Place {
        _ = try await behavior.resolve()
        return Place.Mocks.austin
    }

    func saveLastSearched(_ place: Place) {
        lastSearchedPlace = place
    }

    func weather(at coordinate: Coordinate, unit: TemperatureUnit) async throws -> Weather {
        try await behavior.resolve()
    }
}
#endif
