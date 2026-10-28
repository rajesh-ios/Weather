//
//  NetworkMonitor.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Network
import OSLog

/// Reports when the device regains connectivity, so an offline error can recover by itself.
protocol NetworkMonitoring: AnyObject {
    /// Called on the main actor when the connection comes back after being lost.
    var onReconnect: (() -> Void)? { get set }
}

/// `NWPathMonitor` wrapper. Fires `onReconnect` only on an offline → online transition,
/// not for the initial status or for switching between Wi-Fi and cellular.
final class NetworkMonitor: NetworkMonitoring {
    var onReconnect: (() -> Void)?

    private let monitor = NWPathMonitor()
    private var wasConnected: Bool?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            // Delivered on the main queue (see `start` below), so main-actor state is safe to touch.
            MainActor.assumeIsolated {
                self?.update(isConnected: path.status == .satisfied)
            }
        }
        monitor.start(queue: .main)
    }

    deinit {
        monitor.cancel()
    }

    private func update(isConnected: Bool) {
        defer { wasConnected = isConnected }
        guard wasConnected == false, isConnected else { return }
        Logger.network.info("Connection restored")
        onReconnect?()
    }
}
