//
//  GeocodingDataModel.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/// One entry of the OpenWeather Geocoding API (`/geo/1.0/direct`) response.
struct GeocodingDataModel: Decodable, Equatable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String?
    let state: String?
}

// MARK: - Domain mapping

extension GeocodingDataModel {
    /// Data → domain.
    func toDomain() -> Place {
        Place(name: name, state: state, coordinate: Coordinate(latitude: lat, longitude: lon))
    }
}
