//
//  WeatherDataStore.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/**
 Services for current weather.
 */
protocol WeatherDataStore {
    /**
     Get current conditions for a coordinate.
     */
    func getCurrentWeather(requestModel: GetCurrentWeatherRequestModel) async throws -> CurrentWeatherDataModel
}

extension OpenWeatherDataStore: WeatherDataStore {
    func getCurrentWeather(requestModel: GetCurrentWeatherRequestModel) async throws -> CurrentWeatherDataModel {
        let request = Request(
            route: Routes.Weather.current,
            method: .get,
            params: try authorized([
                Params.Weather.Latitude(requestModel.coordinate.latitude),
                Params.Weather.Longitude(requestModel.coordinate.longitude),
                Params.Weather.Units(requestModel.unit),
                Params.Weather.Language(requestModel.languageCode),
            ])
        )
        return try await send(request: request)
    }
}
