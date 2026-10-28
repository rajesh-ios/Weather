//
//  Strings+CitySearch.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

extension Strings {
    /** City suggestion list shown while searching. */
    enum CitySearch {
        static var promptTitle: String {
            String(localized: "citySearch.prompt.title", defaultValue: "Search Cities", comment: "Title shown when the search bar is active but empty")
        }

        static var promptMessage: String {
            String(localized: "citySearch.prompt.message", defaultValue: "Start typing a city name, e.g. “Aus”.", comment: "Hint shown when the search bar is active but empty")
        }
    }
}
