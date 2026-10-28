//
//  StubLocationProvider.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import Foundation

/// Location stand-in: no system prompt, fixed permission and answer.
struct StubLocationProvider: LocationProviding {
    var permission: LocationPermission = .denied
    var coordinate: StubBehavior<Coordinate> = .failure(WeatherError.locationDenied)

    func requestPermission() async -> LocationPermission { permission }
    func currentCoordinate() async throws -> Coordinate { try await coordinate.resolve() }
}
#endif
