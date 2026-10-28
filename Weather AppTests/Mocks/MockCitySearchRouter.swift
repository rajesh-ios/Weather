//
//  MockCitySearchRouter.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
@testable import Weather_App

final class MockCitySearchRouter: CitySearchRouting {
    private(set) var selected: [Place] = []
    func citySearch(didSelect place: Place) { selected.append(place) }
}
