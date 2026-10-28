//
//  CitySearchViewModel.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
import Observation

/// Implemented by the coordinator: what happens after the user picks a city.
protocol CitySearchRouting: AnyObject {
    func citySearch(didSelect place: Place)
}

/// Drives the suggestion list shown while the search bar is active.
@Observable
final class CitySearchViewModel {
    enum State: Equatable {
        /// Search bar is active but empty.
        case prompt
        case searching
        case results([CitySuggestion])
        case noResults(String)
        case failed(WeatherError)
    }

    private(set) var state: State = .prompt
    /// The row being resolved; the list shows a spinner on it and disables taps.
    private(set) var resolvingID: CitySuggestion.ID?

    @ObservationIgnored weak var router: CitySearchRouting?
    @ObservationIgnored private let searcher: CitySearching
    @ObservationIgnored private var query = ""

    init(searcher: CitySearching) {
        self.searcher = searcher
        searcher.onUpdate = { [weak self] result in self?.handle(result) }
    }

    /// Called on every keystroke. No debounce needed: MKLocalSearchCompleter throttles itself.
    func updateQuery(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != query else { return }
        query = trimmed

        guard !trimmed.isEmpty else {
            searcher.cancel()
            state = .prompt
            return
        }
        // Keep the current rows visible while the next keystroke's results load (no flicker).
        if case .results = state {} else { state = .searching }
        searcher.search(trimmed)
    }

    func select(_ suggestion: CitySuggestion) async {
        guard resolvingID == nil else { return } // ignore double taps
        resolvingID = suggestion.id
        defer { resolvingID = nil }
        do {
            let place = try await searcher.resolve(suggestion)
            router?.citySearch(didSelect: place)
            updateQuery("")
        } catch {
            state = .failed(WeatherError(error))
        }
    }

    // MARK: - Private

    private func handle(_ result: Result<[CitySuggestion], Error>) {
        guard !query.isEmpty else { return } // a late result after the field was cleared
        switch result {
        case .success(let suggestions):
            state = suggestions.isEmpty ? .noResults(query) : .results(suggestions)
        case .failure(let error):
            state = .failed(WeatherError(error))
        }
    }
}
