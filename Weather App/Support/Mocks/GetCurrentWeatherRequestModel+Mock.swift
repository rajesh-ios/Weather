//
//  GetCurrentWeatherRequestModel+Mock.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import Foundation

extension GetCurrentWeatherRequestModel {
    struct Mocks {
        static let austinImperial = GetCurrentWeatherRequestModel(coordinate: Coordinate.Mocks.austin, unit: .imperial)

        /// Explicit language, for asserting the `lang` query parameter.
        static let austinMetricSpanish = GetCurrentWeatherRequestModel(coordinate: Coordinate.Mocks.austin, unit: .metric, languageCode: "es")
    }
}
#endif
