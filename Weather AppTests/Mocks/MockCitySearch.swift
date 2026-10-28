//
//  MockCitySearch.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
@testable import Weather_App

final class MockCitySearch: CitySearching {
    var onUpdate: ((Result<[CitySuggestion], Error>) -> Void)?
    var resolveResult: Result<Place, Error> = .success(Place.Mocks.austin)
    private(set) var fragments: [String] = []
    private(set) var cancelCount = 0
    private(set) var resolved: [CitySuggestion] = []

    func search(_ fragment: String) { fragments.append(fragment) }
    func cancel() { cancelCount += 1 }

    func resolve(_ suggestion: CitySuggestion) async throws -> Place {
        resolved.append(suggestion)
        return try resolveResult.get()
    }

    /// Simulates MapKit delivering results for the latest fragment.
    func deliver(_ result: Result<[CitySuggestion], Error>) { onUpdate?(result) }
}
