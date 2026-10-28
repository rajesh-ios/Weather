//
//  AppCoordinator.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import UIKit

/// A coordinator owns navigation for a flow; screens never present or push each other.
protocol Coordinator: AnyObject {
    func start()
}

/// Root coordinator: builds the weather screen and its city search with their dependencies,
/// and handles routing the ViewModels can't perform themselves (opening Settings, and
/// handing a picked city from the search list to the weather screen).
final class AppCoordinator: Coordinator {
    private let window: UIWindow
    private let dependencies: AppDependencies
    private let navigationController = UINavigationController()
    private var weatherViewModel: WeatherViewModel?
    private weak var weatherViewController: WeatherViewController?

    init(window: UIWindow, dependencies: AppDependencies) {
        self.window = window
        self.dependencies = dependencies
    }

    func start() {
        let viewModel = WeatherViewModel(
            repository: dependencies.weatherRepository,
            location: dependencies.locationProvider,
            network: dependencies.networkMonitor,
            preferences: dependencies.preferences
        )
        viewModel.router = self

        let citySearchViewModel = CitySearchViewModel(searcher: dependencies.citySearch)
        citySearchViewModel.router = self

        let viewController = WeatherViewController(
            viewModel: viewModel,
            citySearchViewModel: citySearchViewModel,
            imageLoader: dependencies.imageLoader
        )
        navigationController.setViewControllers([viewController], animated: false)
        weatherViewModel = viewModel
        weatherViewController = viewController

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}

extension AppCoordinator: WeatherRouting {
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}

extension AppCoordinator: CitySearchRouting {
    func citySearch(didSelect place: Place) {
        weatherViewController?.dismissSearch()
        Task { await weatherViewModel?.show(place) }
    }
}
