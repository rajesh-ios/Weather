//
//  Place.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import Foundation

struct Coordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double
}

/// A resolved city. Persisted as the "last searched city" so relaunch skips re-geocoding.
struct Place: Codable, Equatable {
    let name: String
    let state: String?
    let coordinate: Coordinate

    /// "Austin, Texas" — or just the name when the API omits the state.
    var displayName: String {
        guard let state, !state.isEmpty else { return name }
        return "\(name), \(state)"
    }
}
