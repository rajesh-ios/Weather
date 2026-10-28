//
//  WeatherViewModel.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import Foundation
import Observation
import OSLog

/// Navigation requests the ViewModel can't fulfil itself; implemented by the coordinator.
protocol WeatherRouting: AnyObject {
    func openAppSettings()
}

/// Drives the single weather screen: search, current location, unit toggle, retry.
@Observable
final class WeatherViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(WeatherDisplay)
        case failed(WeatherError)
    }

    private(set) var state: State = .idle
    private(set) var unit: TemperatureUnit

    @ObservationIgnored weak var router: WeatherRouting?

    @ObservationIgnored private let repository: WeatherRepository
    @ObservationIgnored private let location: LocationProviding
    @ObservationIgnored private let network: NetworkMonitoring
    @ObservationIgnored private let preferences: PreferencesStore
    @ObservationIgnored private let formatter: WeatherFormatter

    /// What is on screen, so a unit change can re-fetch the same place.
    @ObservationIgnored private var displayed: (coordinate: Coordinate, title: String?)?
    /// Last user action, replayed by "Try Again".
    @ObservationIgnored private var lastAction: (() async -> Void)?
    /// The in-flight fetch. Starting a new one cancels it, which also cancels its URLSession request.
    @ObservationIgnored private var currentTask: Task<Void, Never>?

    /// - Parameter preferences: used only for the °F/°C choice; city data goes through `repository`.
    init(
        repository: WeatherRepository,
        location: LocationProviding,
        network: NetworkMonitoring,
        preferences: PreferencesStore,
        formatter: WeatherFormatter = WeatherFormatter()
    ) {
        self.repository = repository
        self.location = location
        self.network = network
        self.preferences = preferences
        self.formatter = formatter
        self.unit = preferences.unit
        network.onReconnect = { [weak self] in
            Task { await self?.retryAfterReconnect() }
        }
    }

    // MARK: - Intents

    /// Launch flow:
    /// 1. If a city was searched before, show it (an explicit user choice wins).
    /// 2. Ask for location permission (no-op if already answered).
    /// 3. With no saved city and permission granted, show the current location.
    func start() async {
        let saved = repository.lastSearchedPlace
        if let saved {
            await load(saved.coordinate, title: saved.displayName)
        }
        let permission = await location.requestPermission()
        if saved == nil, permission == .granted {
            await useCurrentLocation()
        }
    }

    func search(_ text: String) async {
        let query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            state = .failed(.emptyQuery)
            return
        }
        lastAction = { [weak self] in await self?.search(query) }
        await perform {
            let place = try await self.repository.searchCity(query)
            return (place.coordinate, place.displayName)
        }
    }

    /// A city picked from the suggestion list: already resolved, so no geocoding needed.
    func show(_ place: Place) async {
        repository.saveLastSearched(place)
        await load(place.coordinate, title: place.displayName)
    }

    func useCurrentLocation() async {
        lastAction = { [weak self] in await self?.useCurrentLocation() }
        // nil title → the formatter uses the station name returned by the API.
        await perform { (try await self.location.currentCoordinate(), nil) }
    }

    func setUnit(_ newUnit: TemperatureUnit) async {
        guard newUnit != unit else { return }
        unit = newUnit
        preferences.unit = newUnit
        if let displayed {
            await load(displayed.coordinate, title: displayed.title)
        }
    }

    func retry() async {
        await lastAction?()
    }

    func openSettings() {
        router?.openAppSettings()
    }

    /// The app came back to the foreground (from the background, or from Settings).
    /// - Location was denied but is now allowed → load the current location.
    /// - A retryable error is showing (offline, server trouble…) → try again.
    /// - Weather is on screen → refresh it silently. Within 10 minutes this is a
    ///   repository cache hit, so it costs no API call.
    /// Anything else (idle, loading, permanent errors) is left for the user to act on.
    func refreshOnForeground() async {
        switch state {
        case .failed(.locationDenied) where location.permission == .granted:
            await useCurrentLocation()
        case .failed(let error) where error.isRetryable:
            await retry()
        case .loaded:
            guard let displayed else { return }
            // current-location result doesn't follow the user if they've moved. Track the
            // source and call `useCurrentLocation()` instead if that matters.
            await perform(silently: true) { (displayed.coordinate, displayed.title) }
        default:
            break
        }
    }

    // MARK: - Private

    /// Connection came back: if the screen shows a connectivity error, recover without a tap.
    private func retryAfterReconnect() async {
        guard case .failed(let error) = state, error.isConnectivityError else { return }
        await retry()
    }

    private func load(_ coordinate: Coordinate, title: String?) async {
        lastAction = { [weak self] in await self?.load(coordinate, title: title) }
        await perform { (coordinate, title) }
    }

    /// Single funnel for every fetch: cancels the previous fetch, shows loading, resolves
    /// where to fetch, fetches, and publishes the result or a friendly error.
    /// Awaiting it lets callers (and tests) know when this particular fetch has finished.
    ///
    /// - Parameter silently: background refresh. Keeps the current content on screen (no
    ///   spinner) and, on failure, keeps it instead of replacing good data with an error.
    private func perform(
        silently: Bool = false,
        _ resolve: @escaping () async throws -> (Coordinate, String?)
    ) async {
        currentTask?.cancel()
        if !silently { state = .loading }

        let task = Task {
            do {
                let (coordinate, title) = try await resolve()
                let weather = try await repository.weather(at: coordinate, unit: unit)
                // A newer request has taken over; it owns `state` now.
                guard !Task.isCancelled else { return }
                displayed = (coordinate, title)
                state = .loaded(formatter.display(for: weather, title: title))
            } catch {
                // Cancellation surfaces as CancellationError or URLError(.cancelled); neither is a user-facing error.
                guard !Task.isCancelled else { return }
                Logger.ui.error("Weather load failed: \(String(describing: error), privacy: .public)")
                if !silently { state = .failed(WeatherError(error)) }
            }
        }
        currentTask = task
        await task.value
    }
}
