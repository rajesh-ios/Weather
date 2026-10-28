//
//  OpenWeatherDataStore.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/**
 Data store for the OpenWeather API.
 Implements one protocol per API group (`WeatherDataStore`, `GeocodingDataStore`) in separate
 files, so repositories depend only on the calls they use.
 */
final class OpenWeatherDataStore: DataStore {
    private let apiKey: String

    /**
     - Parameter apiKey: OpenWeather key from `Config/Secrets.xcconfig`. An empty key fails every
       request with `WeatherError.missingAPIKey` before any network call.
     */
    init(apiKey: String, client: HTTPClient) {
        self.apiKey = apiKey
        super.init(client: client)
    }

    /**
     Every OpenWeather call is authenticated with the API key as the `appid` query param.
     */
    func authorized(_ params: [Param]) throws -> [Param] {
        guard !apiKey.isEmpty else { throw WeatherError.missingAPIKey }
        return params + [Params.Common.AppId(apiKey)]
    }
}
