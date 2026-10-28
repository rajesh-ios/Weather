//
//  Fixtures.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/27/26.
//

import Foundation
import UIKit
@testable import Weather_App

/// Test helpers that aren't models. Model test data lives in `MockModels/` as `Type.Mocks`.
enum Fixtures {
    /// Isolated defaults per test so tests can run in parallel without sharing state.
    static func freshPreferences() -> PreferencesStore {
        let suite = "tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return PreferencesStore(defaults: defaults)
    }

    /// A valid 2×2 PNG, for image-loading tests.
    static let pngData: Data = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        .pngData { $0.fill(CGRect(x: 0, y: 0, width: 2, height: 2)) }
}
