//
//  RequestTests.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
import Testing
@testable import Weather_App

private func queryItems(of url: URL?) -> [String: String] {
    let items = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.queryItems } ?? []
    return Dictionary(items.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })
}

struct RequestTests {
    private struct OptionalParam: Param {
        let key = "optional"
        let value: String? = nil
    }

    @Test func routeComposesBaseURLPathAndQuery() throws {
        let url = try Routes.Weather.current.url(params: [Params.Weather.Latitude(30.27), Params.Weather.Units(.metric)])

        #expect(url.absoluteString.hasPrefix("https://api.openweathermap.org/data/2.5/weather?"))
        #expect(queryItems(of: url) == ["lat": "30.27", "units": "metric"])
    }

    @Test func nilParamsAreLeftOut() throws {
        let url = try Routes.Geocoding.direct.url(params: [OptionalParam(), Params.Geocoding.Limit(5)])

        #expect(queryItems(of: url) == ["limit": "5"])
    }

    @Test func routeWithoutBaseURLThrows() {
        let route: Route = "orphan/path" // base class provides no host
        #expect(throws: WebServiceError.malformedURL) { try route.url() }
    }

    @Test func requestSetsMethodAndAcceptHeader() throws {
        let urlRequest = try Request(route: Routes.Weather.current).urlRequest()

        #expect(urlRequest.httpMethod == "GET")
        #expect(urlRequest.value(forHTTPHeaderField: "Accept") == "application/json")
    }
}
