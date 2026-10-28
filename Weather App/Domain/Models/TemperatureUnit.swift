//
//  TemperatureUnit.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import Foundation

/// User-selectable unit system. Raw values match OpenWeather's `units` query parameter.
enum TemperatureUnit: String, CaseIterable, Codable {
    case imperial
    case metric

    var temperature: UnitTemperature { self == .imperial ? .fahrenheit : .celsius }
    /// OpenWeather returns mph for imperial and m/s for metric.
    var speed: UnitSpeed { self == .imperial ? .milesPerHour : .metersPerSecond }
    var distance: UnitLength { self == .imperial ? .miles : .kilometers }

    /// Short label for the unit toggle ("°F" / "°C").
    var symbol: String { self == .imperial ? "°F" : "°C" }
}
