//
//  GetCitiesRequestModel+Mock.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import Foundation

extension GetCitiesRequestModel {
    struct Mocks {
        /// "Austin" as typed.
        static let austin = GetCitiesRequestModel(query: "Austin")

        /// "Austin, TX, US" as typed.
        static let austinTexas = GetCitiesRequestModel(query: "Austin,TX,US")
    }
}
#endif
