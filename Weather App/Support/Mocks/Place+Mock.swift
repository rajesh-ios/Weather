//
//  Place+Mock.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import Foundation

extension Place {
    struct Mocks {
        /// As OpenWeather geocoding returns it: full state name.
        static let austin = Place(name: "Austin", state: "Texas", coordinate: Coordinate.Mocks.austin)

        /// As a MapKit suggestion resolves it: state code.
        static let austinFromSuggestion = Place(name: "Austin", state: "TX", coordinate: Coordinate.Mocks.austin)

        /// Long name, for layout edge cases.
        static let longName = Place(name: "Rancho Santa Margarita", state: "California", coordinate: Coordinate.Mocks.ranchoSantaMargarita)
    }
}
#endif
