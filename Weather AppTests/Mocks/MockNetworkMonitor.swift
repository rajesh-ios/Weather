//
//  MockNetworkMonitor.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
@testable import Weather_App

final class MockNetworkMonitor: NetworkMonitoring {
    var onReconnect: (() -> Void)?

    /// Simulates the device coming back online.
    func simulateReconnect() { onReconnect?() }
}
