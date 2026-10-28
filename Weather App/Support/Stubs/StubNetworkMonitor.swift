//
//  StubNetworkMonitor.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import Foundation

/// Never reports a reconnect, so previews and UI tests aren't affected by the host's network.
final class StubNetworkMonitor: NetworkMonitoring {
    var onReconnect: (() -> Void)?
}
#endif
