//
//  SceneDelegate.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import UIKit

/// Builds the window and hands control to the `AppCoordinator`.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    /// Strongly held: the coordinator owns the navigation flow for the scene's lifetime.
    private var coordinator: AppCoordinator?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        let coordinator = AppCoordinator(window: window, dependencies: .make())
        coordinator.start()

        self.window = window
        self.coordinator = coordinator
    }
}
