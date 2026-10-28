//
//  WebServiceError.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/**
 Errors thrown by the networking layer. These are technical; `WeatherError(_:)` maps them
 to user-facing messages. `URLError` and `DecodingError` pass through unchanged.
 */
enum WebServiceError: Error, Equatable {
    /** The route or params couldn't form a valid URL. */
    case malformedURL

    /** The response wasn't an `HTTPURLResponse`. */
    case serverResponse

    /** The server answered with a non-2xx status code. */
    case statusCode(Int)
}
