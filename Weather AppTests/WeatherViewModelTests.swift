//
//  WeatherViewModelTests.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/27/26.
//

import Foundation
import Testing
@testable import Weather_App

struct WeatherViewModelTests {
    let repository: MockWeatherRepository
    let location: MockLocationProvider
    let network = MockNetworkMonitor()
    let preferences: PreferencesStore
    let viewModel: WeatherViewModel

    init() {
        repository = MockWeatherRepository()
        location = MockLocationProvider()
        preferences = Fixtures.freshPreferences()
        viewModel = WeatherViewModel(
            repository: repository,
            location: location,
            network: network,
            preferences: preferences,
            formatter: WeatherFormatter(locale: Locale(identifier: "en_US"))
        )
    }

    private var loadedDisplay: WeatherDisplay? {
        if case .loaded(let display) = viewModel.state { return display }
        return nil
    }

    // MARK: - Search

    @Test func searchLoadsWeatherForResolvedCity() async {
        await viewModel.search("  Austin, TX ")

        #expect(repository.searchQueries == ["Austin, TX"]) // trimmed
        #expect(repository.weatherRequests.first?.0 == Coordinate.Mocks.austin)
        #expect(loadedDisplay?.locationName == "Austin, Texas")
    }

    @Test func emptySearchFailsWithoutCallingRepository() async {
        await viewModel.search("   ")

        #expect(viewModel.state == .failed(.emptyQuery))
        #expect(repository.searchQueries.isEmpty)
    }

    @Test func cityNotFoundIsSurfaced() async {
        repository.searchResult = .failure(WeatherError.cityNotFound("Atlantis"))

        await viewModel.search("Atlantis")

        #expect(viewModel.state == .failed(.cityNotFound("Atlantis")))
        #expect(repository.weatherRequests.isEmpty)
    }

    @Test func networkErrorsAreMappedToFriendlyErrors() async {
        repository.weatherResult = .failure(URLError(.notConnectedToInternet))

        await viewModel.search("Austin")

        #expect(viewModel.state == .failed(.offline))
    }

    @Test func retryReplaysLastSearch() async throws {
        repository.weatherResult = .failure(URLError(.timedOut))
        await viewModel.search("Austin")
        #expect(viewModel.state == .failed(.timeout))

        repository.weatherResult = .success(Weather.Mocks.austinImperial)
        await viewModel.retry()

        #expect(repository.searchQueries == ["Austin", "Austin"])
        #expect(loadedDisplay != nil)
    }

    @Test func showingPickedCityLoadsAndSavesItWithoutGeocoding() async {
        let picked = Place.Mocks.austinFromSuggestion

        await viewModel.show(picked)

        #expect(repository.searchQueries.isEmpty) // already resolved by the suggestion list
        #expect(repository.savedPlaces == [picked])
        #expect(loadedDisplay?.locationName == "Austin, TX")
    }

    // MARK: - Cancellation

    @Test func newSearchCancelsInFlightRequest() async {
        repository.weatherDelays = [.seconds(30)] // first request hangs until cancelled

        let first = Task { await viewModel.search("Slow City") }
        while repository.weatherRequests.isEmpty { await Task.yield() } // wait until it's in flight

        await viewModel.search("Austin")
        await first.value

        #expect(repository.cancelledRequests == 1)
        // The cancelled request must not overwrite the newer result with an error.
        #expect(loadedDisplay?.locationName == "Austin, Texas")
    }

    // MARK: - Launch

    @Test func startLoadsLastSearchedCity() async {
        repository.lastSearchedPlace = Place.Mocks.austin

        await viewModel.start()

        #expect(loadedDisplay?.locationName == "Austin, Texas")
        #expect(repository.weatherRequests.count == 1) // saved city only; location not used
        #expect(repository.searchQueries.isEmpty)       // no re-geocoding
        #expect(location.permissionRequests == 1)       // still asks for permission
    }

    @Test func startUsesLocationWhenGrantedAndNoSavedCity() async {
        await viewModel.start()

        #expect(repository.weatherRequests.first?.0 == Coordinate.Mocks.newYork)
        #expect(loadedDisplay?.locationName == "Austin") // falls back to the API's station name
    }

    @Test func startStaysIdleWhenLocationDeniedAndNoSavedCity() async {
        location.answer = .denied

        await viewModel.start()

        #expect(viewModel.state == .idle)
        #expect(repository.weatherRequests.isEmpty)
    }

    // MARK: - Location

    @Test func deniedLocationShowsErrorAndRoutesToSettings() async {
        let router = MockWeatherRouter()
        viewModel.router = router
        location.coordinateResult = .failure(WeatherError.locationDenied)

        await viewModel.useCurrentLocation()
        #expect(viewModel.state == .failed(.locationDenied))

        viewModel.openSettings()
        #expect(router.openSettingsCount == 1)
    }

    // MARK: - Foreground refresh

    @Test func foregroundAfterEnablingLocationInSettingsLoadsCurrentLocation() async {
        location.coordinateResult = .failure(WeatherError.locationDenied)
        await viewModel.useCurrentLocation()
        #expect(viewModel.state == .failed(.locationDenied))

        // User enabled location in Settings and came back.
        location.permission = .granted
        location.coordinateResult = .success(Coordinate.Mocks.newYork)
        await viewModel.refreshOnForeground()

        #expect(loadedDisplay != nil)
    }

    @Test func foregroundWithLocationStillDeniedKeepsError() async {
        location.permission = .denied
        location.coordinateResult = .failure(WeatherError.locationDenied)
        await viewModel.useCurrentLocation()

        await viewModel.refreshOnForeground()

        #expect(viewModel.state == .failed(.locationDenied))
        #expect(repository.weatherRequests.isEmpty)
    }

    @Test func foregroundRefreshesDisplayedCityWithoutGeocoding() async {
        await viewModel.search("Austin")

        await viewModel.refreshOnForeground()

        #expect(repository.searchQueries == ["Austin"]) // no second city lookup
        #expect(repository.weatherRequests.map(\.0) == [Coordinate.Mocks.austin, Coordinate.Mocks.austin])
        #expect(loadedDisplay?.locationName == "Austin, Texas")
    }

    @Test func foregroundRefreshKeepsContentVisibleWhileLoading() async {
        await viewModel.search("Austin")
        let before = viewModel.state
        repository.weatherDelays = [.seconds(30)]

        let refresh = Task { await viewModel.refreshOnForeground() }
        while repository.weatherRequests.count < 2 { await Task.yield() } // refresh in flight

        #expect(viewModel.state == before) // no spinner flash
        refresh.cancel()
        await viewModel.useCurrentLocation() // supersede and finish the hanging refresh
        await refresh.value
    }

    @Test func failedForegroundRefreshKeepsExistingWeather() async {
        await viewModel.search("Austin")
        let before = viewModel.state
        repository.weatherResult = .failure(URLError(.notConnectedToInternet))

        await viewModel.refreshOnForeground()

        #expect(viewModel.state == before) // good data isn't replaced by an error
    }

    @Test func foregroundRetriesRetryableError() async throws {
        repository.weatherResult = .failure(WeatherError.serverError)
        await viewModel.search("Austin")
        #expect(viewModel.state == .failed(.serverError))

        repository.weatherResult = .success(Weather.Mocks.austinImperial)
        await viewModel.refreshOnForeground()

        #expect(loadedDisplay != nil)
    }

    @Test func foregroundDoesNotRetryPermanentError() async {
        repository.searchResult = .failure(WeatherError.cityNotFound("Atlantis"))
        await viewModel.search("Atlantis")

        await viewModel.refreshOnForeground()

        #expect(repository.searchQueries == ["Atlantis"]) // not repeated
        #expect(viewModel.state == .failed(.cityNotFound("Atlantis")))
    }

    @Test func foregroundWhileIdleDoesNothing() async {
        await viewModel.refreshOnForeground()

        #expect(viewModel.state == .idle)
        #expect(repository.weatherRequests.isEmpty)
    }

    // MARK: - Reconnect

    /// `onReconnect` hops into a Task; yield until the retry it started has finished.
    private func waitForReconnectRetry(expectedRequests: Int) async {
        for _ in 0..<100 where repository.weatherRequests.count < expectedRequests || viewModel.state == .loading {
            await Task.yield()
        }
    }

    @Test func reconnectRetriesOfflineError() async throws {
        repository.weatherResult = .failure(URLError(.notConnectedToInternet))
        await viewModel.search("Austin")
        #expect(viewModel.state == .failed(.offline))

        repository.weatherResult = .success(Weather.Mocks.austinImperial)
        network.simulateReconnect()
        await waitForReconnectRetry(expectedRequests: 2)

        #expect(loadedDisplay?.locationName == "Austin, Texas")
    }

    @Test func reconnectIgnoresNonConnectivityErrors() async {
        repository.weatherResult = .failure(WeatherError.serverError)
        await viewModel.search("Austin")

        network.simulateReconnect()
        await waitForReconnectRetry(expectedRequests: 2)

        #expect(repository.weatherRequests.count == 1)
        #expect(viewModel.state == .failed(.serverError))
    }

    @Test func reconnectIgnoresLoadedWeather() async {
        await viewModel.search("Austin")

        network.simulateReconnect()
        await waitForReconnectRetry(expectedRequests: 2)

        #expect(repository.weatherRequests.count == 1)
    }

    // MARK: - Units

    @Test func changingUnitRefetchesSamePlaceAndPersists() async {
        await viewModel.search("Austin")

        await viewModel.setUnit(.metric)

        #expect(repository.weatherRequests.map(\.1) == [.imperial, .metric])
        #expect(repository.weatherRequests.map(\.0) == [Coordinate.Mocks.austin, Coordinate.Mocks.austin])
        #expect(preferences.unit == .metric)
        #expect(viewModel.unit == .metric)
    }

    @Test func settingSameUnitDoesNothing() async {
        await viewModel.setUnit(.imperial)
        #expect(repository.weatherRequests.isEmpty)
    }

    @Test func unitIsRestoredFromPreferences() throws {
        preferences.unit = .metric
        let restored = WeatherViewModel(repository: MockWeatherRepository(), location: location, network: network, preferences: preferences)
        #expect(restored.unit == .metric)
    }
}
