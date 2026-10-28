//
//  WeatherViewController.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import SwiftUI
import UIKit

/// UIKit shell for the weather screen: navigation bar, search controller, location button
/// and unit toggle. The content area is the SwiftUI `WeatherView`, hosted as a child; the
/// search controller's results list is the SwiftUI `CitySearchView`.
/// The controller only forwards user intents to the ViewModels; it holds no state of its own.
final class WeatherViewController: UIViewController {
    private let viewModel: WeatherViewModel
    private let citySearchViewModel: CitySearchViewModel
    private let imageLoader: ImageLoader
    private let searchController: UISearchController

    init(viewModel: WeatherViewModel, citySearchViewModel: CitySearchViewModel, imageLoader: ImageLoader) {
        self.viewModel = viewModel
        self.citySearchViewModel = citySearchViewModel
        self.imageLoader = imageLoader
        let suggestions = UIHostingController(rootView: CitySearchView(viewModel: citySearchViewModel))
        searchController = UISearchController(searchResultsController: suggestions)
        super.init(nibName: nil, bundle: nil)
    }

    /// Closes search (list, keyboard, and text). Called by the coordinator after a selection.
    func dismissSearch() {
        searchController.isActive = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Strings.Weather.title
        view.backgroundColor = .systemBackground

        configureSearch()
        configureBarButtons()
        embedContent()

        // Not viewWillAppear: that doesn't fire when the app returns from the background or
        // from Settings. Selector-based observers are removed automatically on deinit.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sceneWillEnterForeground),
            name: UIScene.willEnterForegroundNotification,
            object: nil
        )

        Task { await viewModel.start() }
    }

    @objc private func sceneWillEnterForeground() {
        Task { await viewModel.refreshOnForeground() }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Setup

    private func configureSearch() {
        let searchBar = searchController.searchBar
        searchBar.placeholder = Strings.Weather.searchPlaceholder
        searchBar.delegate = self
        searchBar.autocorrectionType = .no
        searchBar.autocapitalizationType = .words
        searchBar.returnKeyType = .search
        searchBar.searchTextField.accessibilityIdentifier = AccessibilityID.Weather.searchField

        searchController.searchResultsUpdater = self
        // Keep the location button and unit toggle reachable while the search field is active
        // (by default iOS hides the whole navigation bar during search).
        searchController.hidesNavigationBarDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func configureBarButtons() {
        let locationButton = UIBarButtonItem(
            image: UIImage(systemName: SFSymbol.currentLocation),
            primaryAction: UIAction { [weak self] _ in
                guard let self else { return }
                Task { await self.viewModel.useCurrentLocation() }
            }
        )
        locationButton.accessibilityLabel = Strings.Weather.currentLocationButton
        locationButton.accessibilityIdentifier = AccessibilityID.Weather.currentLocationButton
        navigationItem.leftBarButtonItem = locationButton

        let units = TemperatureUnit.allCases
        let unitControl = UISegmentedControl(items: units.map(\.symbol))
        unitControl.selectedSegmentIndex = units.firstIndex(of: viewModel.unit) ?? 0
        unitControl.accessibilityIdentifier = AccessibilityID.Weather.unitToggle
        unitControl.accessibilityLabel = Strings.Weather.unitToggle
        unitControl.addAction(UIAction { [weak self, weak unitControl] _ in
            guard let self, let index = unitControl?.selectedSegmentIndex, units.indices.contains(index) else { return }
            Task { await self.viewModel.setUnit(units[index]) }
        }, for: .valueChanged)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: unitControl)
    }

    private func embedContent() {
        let host = UIHostingController(rootView: WeatherView(viewModel: viewModel, imageLoader: imageLoader))
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        view.addSubview(host.view)
        // Pinned to the full view (not the safe area): SwiftUI applies safe-area insets itself,
        // which keeps content correct in both orientations and on notched devices.
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        host.didMove(toParent: self)
    }
}

extension WeatherViewController: UISearchBarDelegate {
    /// Return key without picking a suggestion: fall back to OpenWeather geocoding of the typed text.
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let text = searchBar.text ?? ""
        dismissSearch()
        Task { await viewModel.search(text) }
    }
}

extension WeatherViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        // Show the list as soon as the bar is tapped, not only after the first character.
        searchController.showsSearchResultsController = true
        citySearchViewModel.updateQuery(searchController.searchBar.text ?? "")
    }
}

// MARK: - Previews

/// Whole screen: UIKit navigation bar, search bar and toggle around the SwiftUI content.
private func previewScreen(_ viewModel: WeatherViewModel) -> UIViewController {
    UINavigationController(rootViewController: WeatherViewController(
        viewModel: viewModel,
        citySearchViewModel: CitySearchViewModel(searcher: StubCitySearch()),
        imageLoader: ImageLoader.Stubs.icon
    ))
}

#Preview("Screen – first launch, location denied") {
    previewScreen(.preview())
}

#Preview("Screen – saved city on relaunch") {
    previewScreen(.preview(lastSearchedPlace: Place.Mocks.austin))
}

#Preview("Screen – saved city, landscape", traits: .landscapeLeft) {
    previewScreen(.preview(lastSearchedPlace: Place.Mocks.austin))
}

#Preview("Screen – metric, dark mode") {
    let screen = previewScreen(.preview(.success(Weather.Mocks.austinMetric), lastSearchedPlace: Place.Mocks.austin, unit: .metric))
    screen.overrideUserInterfaceStyle = .dark
    return screen
}
