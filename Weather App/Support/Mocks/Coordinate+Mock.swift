//
//  Coordinate+Mock.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import Foundation

extension Coordinate {
    struct Mocks {
        static let austin = Coordinate(latitude: 30.27, longitude: -97.74)
        static let newYork = Coordinate(latitude: 40.71, longitude: -74.0)
        static let ranchoSantaMargarita = Coordinate(latitude: 33.64, longitude: -117.60)
        /// Latitude beyond ±90°: rejected before any network call.
        static let outOfRange = Coordinate(latitude: 120, longitude: 0)
    }
}
#endif
