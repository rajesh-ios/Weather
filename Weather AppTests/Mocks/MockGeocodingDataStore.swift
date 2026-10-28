//
//  MockGeocodingDataStore.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
@testable import Weather_App

final class MockGeocodingDataStore: GeocodingDataStore {
    // MARK: Test expectations

    var getCitiesResult: Result<[GeocodingDataModel], Error> = .success([GeocodingDataModel.Mocks.austin])

    // MARK: Argument expectations

    private(set) var getCitiesCalls: [GetCitiesRequestModel] = []

    // MARK: Test methods

    func getCities(requestModel: GetCitiesRequestModel) async throws -> [GeocodingDataModel] {
        getCitiesCalls.append(requestModel)
        return try getCitiesResult.get()
    }
}
