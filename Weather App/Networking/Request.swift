//
//  Request.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/**
 Describes one API call: which route, which HTTP method, which params.
 `DataStore.send(request:)` turns it into a `URLRequest`.
 */
struct Request {
    enum Method: String {
        case get = "GET"
    }

    let route: Route
    let method: Method
    let params: [Param]

    init(route: Route, method: Method = .get, params: [Param] = []) {
        self.route = route
        self.method = method
        self.params = params
    }

    /** Builds the `URLRequest` with the common headers. */
    func urlRequest() throws -> URLRequest {
        var request = URLRequest(url: try route.url(params: params))
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
