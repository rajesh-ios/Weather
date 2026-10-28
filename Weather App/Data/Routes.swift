//
//  Routes.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/**
 Service routes, grouped by API.
 */
struct Routes {
    struct Weather {
        /** Current conditions by coordinate. Docs: https://openweathermap.org/current */
        static let current: OpenWeatherRoute = "data/2.5/weather"
    }

    struct Geocoding {
        /** City name → coordinates (up to 5 matches). Docs: https://openweathermap.org/api/geocoding-api */
        static let direct: OpenWeatherRoute = "geo/1.0/direct"
    }
}

/**
 API route relative to `https://api.openweathermap.org`.
 */
final class OpenWeatherRoute: Route {
    override func baseURL() -> URL? {
        URL(string: "https://api.openweathermap.org")
    }
}
