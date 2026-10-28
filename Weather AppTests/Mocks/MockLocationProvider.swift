//
//  MockLocationProvider.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
@testable import Weather_App

final class MockLocationProvider: LocationProviding {
    var permission: LocationPermission
    var answer: LocationPermission
    var coordinateResult: Result<Coordinate, Error> = .success(Coordinate.Mocks.newYork)
    private(set) var permissionRequests = 0

    init(permission: LocationPermission = .notDetermined, answer: LocationPermission = .granted) {
        self.permission = permission
        self.answer = answer
    }

    func requestPermission() async -> LocationPermission {
        permissionRequests += 1
        if permission == .notDetermined { permission = answer }
        return permission
    }

    func currentCoordinate() async throws -> Coordinate {
        try coordinateResult.get()
    }
}
