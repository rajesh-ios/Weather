//
//  AppDelegate.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import UIKit

/// UIKit app entry point. No storyboards: the scene is configured in code.
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // The generated Info.plist has no scene delegate entry, so we name it here
        // rather than maintaining a hand-written UIApplicationSceneManifest.
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
}
