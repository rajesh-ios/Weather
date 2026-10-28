//
//  Param.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/**
 A type-safe URL query parameter. Each API parameter is declared once as a small struct
 (see `Data/Params.swift`), so keys aren't retyped as strings at every call site.
 */
protocol Param {
    /** The query parameter name. */
    var key: String { get }

    /** The query parameter value; `nil` means "leave it out of the request". */
    var value: String? { get }
}
