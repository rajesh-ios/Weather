//
//  Route.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/**
 Base class for an API route: a path relative to a base URL that each subclass provides.
 Routes are declared as string literals, e.g. `static let current: OpenWeatherRoute = "data/2.5/weather"`.
 */

class Route: ExpressibleByStringLiteral {
    /** Path component appended to `baseURL()`. */
    let path: String

    required init(stringLiteral value: String) {
        path = value
    }

    /** Overridden per API host. */
    func baseURL() -> URL? {
        nil
    }

    /**
     Composes the final URL.
     - Parameter params: Added as query items. Params with a `nil` value are skipped.
     */
    final func url(params: [Param] = []) throws -> URL {
        guard let baseURL = baseURL(),
              var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        else { throw WebServiceError.malformedURL }

        let queryItems = params.compactMap { param in
            param.value.map { URLQueryItem(name: param.key, value: $0) }
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else { throw WebServiceError.malformedURL }
        return url
    }
}
