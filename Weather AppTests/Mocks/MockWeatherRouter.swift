//
//  MockWeatherRouter.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
@testable import Weather_App

final class MockWeatherRouter: WeatherRouting {
    private(set) var openSettingsCount = 0
    func openAppSettings() { openSettingsCount += 1 }
}
