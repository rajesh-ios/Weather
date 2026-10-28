//
//  Strings+Details.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

extension Strings {
    /** Titles of the weather detail tiles. */
    enum Details {
        static var feelsLike: String {
            String(localized: "details.feelsLike", defaultValue: "Feels Like", comment: "Detail tile: apparent temperature")
        }

        static var humidity: String {
            String(localized: "details.humidity", defaultValue: "Humidity", comment: "Detail tile: relative humidity")
        }

        static var wind: String {
            String(localized: "details.wind", defaultValue: "Wind", comment: "Detail tile: wind speed")
        }

        static var pressure: String {
            String(localized: "details.pressure", defaultValue: "Pressure", comment: "Detail tile: air pressure")
        }

        static var visibility: String {
            String(localized: "details.visibility", defaultValue: "Visibility", comment: "Detail tile: how far one can see")
        }

        static var cloudCover: String {
            String(localized: "details.cloudCover", defaultValue: "Cloud Cover", comment: "Detail tile: percentage of sky covered by clouds")
        }

        static var sunrise: String {
            String(localized: "details.sunrise", defaultValue: "Sunrise", comment: "Detail tile: sunrise time")
        }

        static var sunset: String {
            String(localized: "details.sunset", defaultValue: "Sunset", comment: "Detail tile: sunset time")
        }
    }
}
