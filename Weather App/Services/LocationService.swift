//
//  LocationService.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import CoreLocation
import OSLog

enum LocationPermission: Equatable {
    case notDetermined
    case granted
    case denied
}

/// CoreLocation-free seam so the ViewModel can be tested without a device.
protocol LocationProviding {
    var permission: LocationPermission { get }
    /// Shows the system prompt if needed and returns the user's answer.
    func requestPermission() async -> LocationPermission
    func currentCoordinate() async throws -> Coordinate
}

/// Wraps `CLLocationManager`'s delegate callbacks in async/await.
final class LocationService: NSObject, LocationProviding {
    private let manager = CLLocationManager()
    private var permissionContinuation: CheckedContinuation<LocationPermission, Never>?
    private var locationContinuation: CheckedContinuation<Coordinate, Error>?

    override init() {
        super.init()
        manager.delegate = self
        // City-level weather doesn't need GPS precision; this is faster and saves battery.
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    var permission: LocationPermission {
        Self.permission(from: manager.authorizationStatus)
    }

    func requestPermission() async -> LocationPermission {
        guard manager.authorizationStatus == .notDetermined else { return permission }
        // queueing; the app only asks once at launch. Keep a list of continuations if that changes.
        guard permissionContinuation == nil else { return permission }
        return await withCheckedContinuation { continuation in
            permissionContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    func currentCoordinate() async throws -> Coordinate {
        switch permission {
        case .denied: throw WeatherError.locationDenied
        case .notDetermined:
            guard await requestPermission() == .granted else { throw WeatherError.locationDenied }
        case .granted: break
        }
        guard locationContinuation == nil else { throw WeatherError.locationUnavailable }
        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation = continuation
            manager.requestLocation()
        }
    }

    private static func permission(from status: CLAuthorizationStatus) -> LocationPermission {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: .granted
        case .notDetermined: .notDetermined
        default: .denied // .denied, .restricted, and any future case
        }
    }
}

// The delegate protocol is nonisolated, while this module defaults to @MainActor.
// CLLocationManager calls back on the thread it was created on — the main thread here —
// so `MainActor.assumeIsolated` is safe and avoids an extra hop.
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            // Also fires once when the manager is created; ignore until the user answers.
            guard manager.authorizationStatus != .notDetermined else { return }
            permissionContinuation?.resume(returning: permission)
            permissionContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last.map {
            Coordinate(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude)
        }
        MainActor.assumeIsolated {
            if let coordinate {
                locationContinuation?.resume(returning: coordinate)
            } else {
                locationContinuation?.resume(throwing: WeatherError.locationUnavailable)
            }
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let denied = (error as? CLError)?.code == .denied
        Logger.location.error("Location request failed: \(error.localizedDescription, privacy: .public)")
        MainActor.assumeIsolated {
            locationContinuation?.resume(throwing: denied ? WeatherError.locationDenied : WeatherError.locationUnavailable)
            locationContinuation = nil
        }
    }
}
