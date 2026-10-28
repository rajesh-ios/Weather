//
//  GeocodingDataModel+Mock.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import Foundation

extension GeocodingDataModel {
    struct Mocks {
        static let austin = GeocodingDataModel(
            name: "Austin",
            lat: Coordinate.Mocks.austin.latitude,
            lon: Coordinate.Mocks.austin.longitude,
            country: "US",
            state: "Texas"
        )

        /// A non-US match.
        static let paris = GeocodingDataModel(name: "Paris", lat: 48.85, lon: 2.35, country: "FR", state: nil)
    }
}
#endif
