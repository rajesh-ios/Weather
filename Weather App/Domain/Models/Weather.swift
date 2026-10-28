//
//  Weather.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/// Domain model for current conditions. Independent of OpenWeather's JSON shape:
/// the API's data model (`CurrentWeatherDataModel`) is converted to this in the repository, so presentation
/// code never changes when the API does.
///
/// Measurements are in the units of `unit` (°F/mph or °C/m/s), except where noted.
struct Weather: Equatable {
    let unit: TemperatureUnit
    /// Station name reported by the API (may be empty).
    let stationName: String
    let conditionDescription: String
    /// OpenWeather icon code such as "01d"; nil when the API sends no condition.
    let iconCode: String?

    let temperature: Double
    let feelsLike: Double
    let low: Double
    let high: Double

    /// 0–100.
    let humidity: Double?
    let windSpeed: Double?
    /// Hectopascals, regardless of `unit`.
    let pressure: Double?
    /// Meters, regardless of `unit`.
    let visibility: Double?
    /// 0–100.
    let cloudCover: Double?

    let sunrise: Date?
    let sunset: Date?
    /// The city's own time zone, used to show sunrise/sunset in local city time.
    let timeZone: TimeZone?
}
