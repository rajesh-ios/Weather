//
//  GetCurrentWeatherRequestModel.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

struct GetCurrentWeatherRequestModel: Equatable {
    /** Where to get the weather for. */
    let coordinate: Coordinate

    /** Unit system the response values should be in. */
    let unit: TemperatureUnit

    /** Language for the condition description, e.g. "en" or "es". */
    var languageCode: String = Locale.current.language.languageCode?.identifier ?? "en"
}
