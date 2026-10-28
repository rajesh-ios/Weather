//
//  CitySearchView.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import SwiftUI

/// Suggestion list shown as the search controller's results while the user types.
struct CitySearchView: View {
    let viewModel: CitySearchViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .prompt:
                ContentUnavailableView {
                    Label(Strings.CitySearch.promptTitle, systemImage: SFSymbol.search)
                        .accessibilityIdentifier(AccessibilityID.CitySearch.prompt)
                } description: {
                    Text(Strings.CitySearch.promptMessage)
                }
            case .searching:
                ProgressView()
            case .noResults(let query):
                ContentUnavailableView.search(text: query)
            case .failed(let error):
                ContentUnavailableView(
                    error.localizedDescription,
                    systemImage: SFSymbol.warning,
                    description: Text(error.recoverySuggestion ?? "")
                )
            case .results(let suggestions):
                List(suggestions) { suggestion in
                    row(for: suggestion)
                }
                .listStyle(.plain)
                .scrollDismissesKeyboard(.immediately)
                .accessibilityIdentifier(AccessibilityID.CitySearch.suggestions)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private func row(for suggestion: CitySuggestion) -> some View {
        Button {
            Task { await viewModel.select(suggestion) }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .foregroundStyle(.primary)
                    Text(suggestion.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if viewModel.resolvingID == suggestion.id {
                    ProgressView()
                }
            }
            .contentShape(Rectangle())
        }
        .disabled(viewModel.resolvingID != nil)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Previews

#Preview("Prompt – empty search bar") {
    CitySearchView(viewModel: CitySearchViewModel(searcher: StubCitySearch()))
}

#Preview("Searching") {
    let viewModel = CitySearchViewModel(searcher: StubCitySearch(respondsToSearch: false))
    CitySearchView(viewModel: viewModel)
        .task { viewModel.updateQuery("Au") }
}

#Preview("Results") {
    let viewModel = CitySearchViewModel(searcher: StubCitySearch())
    CitySearchView(viewModel: viewModel)
        .task { viewModel.updateQuery("Au") }
}

#Preview("Results – long city name") {
    let viewModel = CitySearchViewModel(searcher: StubCitySearch())
    CitySearchView(viewModel: viewModel)
        .task { viewModel.updateQuery("Tru") }
}

#Preview("Resolving a tapped city") {
    let viewModel = CitySearchViewModel(searcher: StubCitySearch(resolveBehavior: .loading))
    CitySearchView(viewModel: viewModel)
        .task {
            viewModel.updateQuery("Au")
            await viewModel.select(CitySuggestion.Mocks.austinTX)
        }
}

#Preview("No results") {
    let viewModel = CitySearchViewModel(searcher: StubCitySearch())
    CitySearchView(viewModel: viewModel)
        .task { viewModel.updateQuery("Zzyzx") }
}

#Preview("Error – offline") {
    let viewModel = CitySearchViewModel(searcher: StubCitySearch(searchError: URLError(.notConnectedToInternet)))
    CitySearchView(viewModel: viewModel)
        .task { viewModel.updateQuery("Au") }
}

#Preview("Results – dark mode") {
    let viewModel = CitySearchViewModel(searcher: StubCitySearch())
    CitySearchView(viewModel: viewModel)
        .task { viewModel.updateQuery("Au") }
        .preferredColorScheme(.dark)
}

#Preview("Results – largest Dynamic Type") {
    let viewModel = CitySearchViewModel(searcher: StubCitySearch())
    CitySearchView(viewModel: viewModel)
        .task { viewModel.updateQuery("Au") }
        .environment(\.dynamicTypeSize, .accessibility5)
}
