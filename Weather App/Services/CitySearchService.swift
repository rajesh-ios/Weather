//
//  CitySearchService.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import MapKit
import OSLog

/// One row in the city suggestion list, e.g. "Austin, TX" / "United States" or "Paris" / "France".
struct CitySuggestion: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
}

/// Type-ahead city search. Results are pushed through `onUpdate` because the
/// underlying completer is delegate-driven and throttles its own requests.
protocol CitySearching: AnyObject {
    /// Called with suggestions for the latest fragment. An empty array means "no matches".
    var onUpdate: ((Result<[CitySuggestion], Error>) -> Void)? { get set }
    func search(_ fragment: String)
    func cancel()
    /// Turns a suggestion into a place with coordinates.
    func resolve(_ suggestion: CitySuggestion) async throws -> Place
}

/// Apple MapKit implementation: `MKLocalSearchCompleter` for suggestions (prefix matching,
/// free, no API key) and `MKLocalSearch` to resolve the chosen suggestion's coordinates.
final class MapKitCitySearchService: NSObject, CitySearching {
    var onUpdate: ((Result<[CitySuggestion], Error>) -> Void)?

    private let completer = MKLocalSearchCompleter()
    /// MapKit completions are needed again to resolve a selection; keyed by suggestion id.
    private var completions: [CitySuggestion.ID: MKLocalSearchCompletion] = [:]

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
        if #available(iOS 18.0, *) {
            completer.addressFilter = MKAddressFilter(including: .locality) // cities only
        }
        // On iOS 17 there's no city-only filter; countries ("Australia") still appear, but
        // they come back with an empty subtitle, so the delegate drops them below.
    }

    func search(_ fragment: String) {
        completer.queryFragment = fragment
    }

    func cancel() {
        completer.cancel()
        completions = [:]
    }

    func resolve(_ suggestion: CitySuggestion) async throws -> Place {
        guard let completion = completions[suggestion.id] else {
            throw WeatherError.cityNotFound(suggestion.title)
        }
        let response = try await MKLocalSearch(request: MKLocalSearch.Request(completion: completion)).start()
        guard let item = response.mapItems.first else {
            throw WeatherError.cityNotFound(suggestion.title)
        }
        let placemark = item.placemark
        return Place(
            name: placemark.locality ?? item.name ?? suggestion.title,
            state: placemark.administrativeArea, // "TX", "Île-de-France"
            coordinate: Coordinate(latitude: placemark.coordinate.latitude, longitude: placemark.coordinate.longitude)
        )
    }
}

// The delegate protocol is nonisolated; the completer calls back on the main thread
// (where it was created), so `MainActor.assumeIsolated` is safe. See LocationService.
extension MapKitCitySearchService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        MainActor.assumeIsolated {
            var suggestions: [CitySuggestion] = []
            completions = [:]
            for result in completer.results where !result.subtitle.isEmpty { // empty subtitle = a country (iOS 17)
                let id = "\(result.title)|\(result.subtitle)"
                guard completions[id] == nil else { continue } // MapKit occasionally repeats a row
                completions[id] = result
                suggestions.append(CitySuggestion(id: id, title: result.title, subtitle: result.subtitle))
            }
            onUpdate?(.success(suggestions))
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // MapKit reports "no matches" as an error; the UI treats it as an empty list.
        let noMatches = (error as? MKError)?.code == .placemarkNotFound
        if !noMatches {
            Logger.data.error("City search failed: \(error.localizedDescription, privacy: .public)")
        }
        MainActor.assumeIsolated {
            onUpdate?(noMatches ? .success([]) : .failure(error))
        }
    }
}
