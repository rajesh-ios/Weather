//
//  GetCitiesRequestModel.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

struct GetCitiesRequestModel: Equatable {
    /** Geocoding query in `{city},{state code},{country code}` form, e.g. "Austin,TX,US". */
    let query: String

    /** Maximum number of matches; OpenWeather caps this at 5. */
    var limit: Int = 5
}
