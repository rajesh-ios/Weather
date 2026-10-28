//
//  CitySuggestion+Mock.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import Foundation

extension CitySuggestion {
    struct Mocks {
        static let austinTX = make("Austin, TX")
        static let austellGA = make("Austell, GA")
        static let augustaGA = make("Augusta, GA")
        static let springfieldIL = make("Springfield, IL")

        /// Long name, for row-wrapping edge cases.
        static let truthOrConsequencesNM = make("Truth or Consequences, NM")

        static let all = [austinTX, austellGA, augustaGA, springfieldIL, truthOrConsequencesNM]

        /// Same id format as `MapKitCitySearchService` ("title|subtitle").
        private static func make(_ title: String) -> CitySuggestion {
            CitySuggestion(id: "\(title)|United States", title: title, subtitle: "United States")
        }
    }
}
#endif
