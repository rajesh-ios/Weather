//
//  MockWeatherDataStore.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
@testable import Weather_App

final class MockWeatherDataStore: WeatherDataStore {
    // MARK: Test expectations

    var getCurrentWeatherResult: Result<CurrentWeatherDataModel, Error> = .success(CurrentWeatherDataModel.Mocks.austinClearSky)

    // MARK: Argument expectations

    private(set) var getCurrentWeatherCalls: [GetCurrentWeatherRequestModel] = []

    // MARK: Test methods

    func getCurrentWeather(requestModel: GetCurrentWeatherRequestModel) async throws -> CurrentWeatherDataModel {
        getCurrentWeatherCalls.append(requestModel)
        return try getCurrentWeatherResult.get()
    }
}
