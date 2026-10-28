//
//  GeocodingDataStore.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/**
 Services for turning city names into coordinates.
 */
protocol GeocodingDataStore {
    /**
     Get cities matching a full city name (no prefix matching).
     */
    func getCities(requestModel: GetCitiesRequestModel) async throws -> [GeocodingDataModel]
}

extension OpenWeatherDataStore: GeocodingDataStore {
    func getCities(requestModel: GetCitiesRequestModel) async throws -> [GeocodingDataModel] {
        let request = Request(
            route: Routes.Geocoding.direct,
            method: .get,
            params: try authorized([
                Params.Geocoding.Query(requestModel.query),
                Params.Geocoding.Limit(requestModel.limit),
            ])
        )
        return try await send(request: request)
    }
}
