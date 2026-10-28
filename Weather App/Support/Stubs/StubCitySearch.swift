//
//  StubCitySearch.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import Foundation

/// City search stand-in: prefix-matches a fixed list (like MapKit autocomplete) and
/// resolves a suggestion by splitting its title ("Austin, TX" → Austin, TX).
final class StubCitySearch: CitySearching {
    var onUpdate: ((Result<[CitySuggestion], Error>) -> Void)?
    var cities: [CitySuggestion]
    /// When set, every search fails with it.
    var searchError: Error?
    /// `false` never answers a search, so the list stays in its "searching" state.
    var respondsToSearch: Bool
    /// `.loading` keeps the tapped row's spinner showing.
    var resolveBehavior: StubBehavior<Void>

    init(
        cities: [CitySuggestion] = CitySuggestion.Mocks.all,
        searchError: Error? = nil,
        respondsToSearch: Bool = true,
        resolveBehavior: StubBehavior<Void> = .success(())
    ) {
        self.cities = cities
        self.searchError = searchError
        self.respondsToSearch = respondsToSearch
        self.resolveBehavior = resolveBehavior
    }

    func search(_ fragment: String) {
        guard respondsToSearch else { return }
        if let searchError {
            onUpdate?(.failure(searchError))
            return
        }
        let matches = cities.filter { $0.title.lowercased().hasPrefix(fragment.lowercased()) }
        onUpdate?(.success(matches))
    }

    func cancel() {}

    func resolve(_ suggestion: CitySuggestion) async throws -> Place {
        try await resolveBehavior.resolve()
        let parts = suggestion.title.components(separatedBy: ", ")
        return Place(name: parts[0], state: parts.count > 1 ? parts.last : nil, coordinate: Coordinate.Mocks.austin)
    }
}
#endif
