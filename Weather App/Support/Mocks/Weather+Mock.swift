//
//  Weather+Mock.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import Foundation

extension Weather {
    struct Mocks {
        /// Austin clear sky, values in °F / mph.
        static let austinImperial = CurrentWeatherDataModel.Mocks.austinClearSky.toDomain(unit: .imperial)

        /// Austin clear sky, values in °C / m/s.
        static let austinMetric = CurrentWeatherDataModel.Mocks.austinClearSky.toDomain(unit: .metric)

        /// Every optional field missing.
        static let minimal = CurrentWeatherDataModel.Mocks.minimal.toDomain(unit: .imperial)

        /// Extreme values and a long condition, for layout edge cases (wide numbers, wrapping text).
        static let blizzard = Weather(
            unit: .imperial,
            stationName: "Barrow",
            conditionDescription: "heavy shower snow with freezing fog",
            iconCode: "13n",
            temperature: -42.6,
            feelsLike: -71.2,
            low: -48,
            high: -38,
            humidity: 100,
            windSpeed: 48.3,
            pressure: 1052,
            visibility: 120,
            cloudCover: 100,
            sunrise: nil,
            sunset: nil,
            timeZone: TimeZone(identifier: "America/Anchorage")
        )
    }
}
#endif
