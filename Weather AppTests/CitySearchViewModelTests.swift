//
//  CitySearchViewModelTests.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
import Testing
@testable import Weather_App

struct CitySearchViewModelTests {
    let searcher = MockCitySearch()
    let router = MockCitySearchRouter()
    let viewModel: CitySearchViewModel

    init() {
        viewModel = CitySearchViewModel(searcher: searcher)
        viewModel.router = router
    }

    // MARK: - Typing

    @Test func startsWithPrompt() {
        #expect(viewModel.state == .prompt)
    }

    @Test func typingSearchesTrimmedTextAndShowsResults() {
        viewModel.updateQuery("  Aus ")
        #expect(searcher.fragments == ["Aus"])
        #expect(viewModel.state == .searching)

        searcher.deliver(.success([CitySuggestion.Mocks.austinTX]))
        #expect(viewModel.state == .results([CitySuggestion.Mocks.austinTX]))
    }

    @Test func unchangedQueryDoesNotSearchAgain() {
        viewModel.updateQuery("Aus")
        viewModel.updateQuery("Aus ")
        #expect(searcher.fragments == ["Aus"])
    }

    @Test func keepsRowsVisibleWhileNextKeystrokeLoads() {
        viewModel.updateQuery("Aus")
        searcher.deliver(.success([CitySuggestion.Mocks.austinTX]))

        viewModel.updateQuery("Aust")

        #expect(viewModel.state == .results([CitySuggestion.Mocks.austinTX])) // no flicker to a spinner
    }

    @Test func emptyResultsShowNoResults() {
        viewModel.updateQuery("Zzz")
        searcher.deliver(.success([]))
        #expect(viewModel.state == .noResults("Zzz"))
    }

    @Test func searchErrorsAreMapped() {
        viewModel.updateQuery("Aus")
        searcher.deliver(.failure(URLError(.notConnectedToInternet)))
        #expect(viewModel.state == .failed(.offline))
    }

    @Test func clearingTheFieldCancelsAndShowsPrompt() {
        viewModel.updateQuery("Aus")
        viewModel.updateQuery("")

        #expect(searcher.cancelCount == 1)
        #expect(viewModel.state == .prompt)
    }

    @Test func lateResultsAfterClearingAreIgnored() {
        viewModel.updateQuery("Aus")
        viewModel.updateQuery("")
        searcher.deliver(.success([CitySuggestion.Mocks.austinTX]))

        #expect(viewModel.state == .prompt)
    }

    // MARK: - Selection

    @Test func selectingResolvesRoutesAndResets() async {
        viewModel.updateQuery("Aus")
        searcher.deliver(.success([CitySuggestion.Mocks.austinTX]))

        await viewModel.select(CitySuggestion.Mocks.austinTX)

        #expect(searcher.resolved == [CitySuggestion.Mocks.austinTX])
        #expect(router.selected == [Place.Mocks.austin])
        #expect(viewModel.state == .prompt)
        #expect(viewModel.resolvingID == nil)
    }

    @Test func failedResolveShowsErrorAndDoesNotRoute() async {
        searcher.resolveResult = .failure(WeatherError.cityNotFound("Austin, TX"))
        viewModel.updateQuery("Aus")

        await viewModel.select(CitySuggestion.Mocks.austinTX)

        #expect(router.selected.isEmpty)
        #expect(viewModel.state == .failed(.cityNotFound("Austin, TX")))
        #expect(viewModel.resolvingID == nil)
    }
}
