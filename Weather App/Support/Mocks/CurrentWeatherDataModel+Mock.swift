//
//  CurrentWeatherDataModel+Mock.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import Foundation

extension CurrentWeatherDataModel {
    struct Mocks {
        /// Trimmed real response from `/data/2.5/weather` (imperial). Raw JSON for HTTP-level tests.
        static let austinClearSkyJSON = """
        {
          "coord": {"lon": -97.74, "lat": 30.27},
          "weather": [{"id": 800, "main": "Clear", "description": "clear sky", "icon": "01d"}],
          "main": {"temp": 72.4, "feels_like": 71.6, "temp_min": 68.0, "temp_max": 75.2, "pressure": 1015, "humidity": 40},
          "visibility": 10000,
          "wind": {"speed": 8.05, "deg": 180},
          "clouds": {"all": 0},
          "dt": 1761580800,
          "sys": {"country": "US", "sunrise": 1761569400, "sunset": 1761609600},
          "timezone": -18000,
          "name": "Austin"
        }
        """

        /// Only the required `main` block; every optional field is missing.
        static let minimalJSON = """
        {"main": {"temp": 50, "feels_like": 48, "temp_min": 45, "temp_max": 55}}
        """

        static let austinClearSky = decode(austinClearSkyJSON)
        static let minimal = decode(minimalJSON)

        /// Decodes exactly as `DataStore` does. The model has no memberwise init (it's
        /// `Decodable` with a custom decoder), so mocks are built from JSON. A typo in the JSON
        /// above crashes the test run immediately, which is the desired fixture behavior.
        private static func decode(_ json: String) -> CurrentWeatherDataModel {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            // swiftlint:disable:next force_try
            return try! decoder.decode(CurrentWeatherDataModel.self, from: Data(json.utf8))
        }
    }
}
#endif
