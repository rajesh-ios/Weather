//
//  Logger+App.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import OSLog

/// Unified logging categories. View in Console.app or Xcode by filtering on the subsystem.
/// Dynamic values are private by default in release logs. Only non-sensitive values
/// (paths, status codes, error cases) are marked `.public`, and the API key is never logged.
/// `nonisolated`: Logger is thread-safe and is also used from CoreLocation's nonisolated callbacks.
extension Logger {
    private nonisolated static let subsystem = Bundle.main.bundleIdentifier ?? "WeatherApp"

    nonisolated static let network = Logger(subsystem: subsystem, category: "network")
    nonisolated static let data = Logger(subsystem: subsystem, category: "data")
    nonisolated static let location = Logger(subsystem: subsystem, category: "location")
    nonisolated static let ui = Logger(subsystem: subsystem, category: "ui")
}
