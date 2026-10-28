//
//  SFSymbol.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/**
 SF Symbol names used in the app, so a typo is a compile error instead of a blank icon.
 Browse names in Apple's SF Symbols app.
 */
enum SFSymbol {
    // MARK: Actions and states

    static let search = "magnifyingglass"
    static let currentLocation = "location"
    static let warning = "exclamationmark.triangle"
    static let weatherPlaceholder = "cloud.sun"

    // MARK: Weather details

    static let feelsLike = "thermometer.medium"
    static let humidity = "humidity"
    static let wind = "wind"
    static let pressure = "gauge.medium"
    static let visibility = "eye"
    static let cloudCover = "cloud"
    static let sunrise = "sunrise"
    static let sunset = "sunset"
}
