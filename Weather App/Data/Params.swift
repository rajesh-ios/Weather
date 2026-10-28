//
//  Params.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/**
 Query parameters, grouped by API.
 */
struct Params {
    struct Common {
        /** API key; required on every OpenWeather call. */
        struct AppId: Param {
            let key = "appid"
            let value: String?
            init(_ apiKey: String) { value = apiKey }
        }
    }

    struct Weather {
        struct Latitude: Param {
            let key = "lat"
            let value: String?
            init(_ latitude: Double) { value = String(latitude) }
        }

        struct Longitude: Param {
            let key = "lon"
            let value: String?
            init(_ longitude: Double) { value = String(longitude) }
        }

        /** `imperial` (°F, mph) or `metric` (°C, m/s). */
        struct Units: Param {
            let key = "units"
            let value: String?
            init(_ unit: TemperatureUnit) { value = unit.rawValue }
        }

        /** Language of the condition text ("clear sky" / "cielo claro"). */
        struct Language: Param {
            let key = "lang"
            let value: String?
            init(_ languageCode: String) { value = languageCode }
        }
    }

    struct Geocoding {
        /** `{city},{state code},{country code}`, e.g. "Austin,TX,US". */
        struct Query: Param {
            let key = "q"
            let value: String?
            init(_ query: String) { value = query }
        }

        /** Maximum number of matches; OpenWeather caps this at 5. */
        struct Limit: Param {
            let key = "limit"
            let value: String?
            init(_ limit: Int) { value = String(limit) }
        }
    }
}
