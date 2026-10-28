//
//  MockHTTPClient.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
@testable import Weather_App

/// Returns canned responses and records every request.
final class MockHTTPClient: HTTPClient {
    /// Used for every call once `queuedResults` is empty.
    var result: Result<(Data, Int), Error>
    /// Consumed one per call, first in first out — for scripting sequences like 503 → 200.
    var queuedResults: [Result<(Data, Int), Error>] = []
    /// Response headers, e.g. `["Retry-After": "2"]`.
    var headers: [String: String] = [:]

    private(set) var requests: [URLRequest] = []
    var requestedURLs: [URL] { requests.compactMap(\.url) }

    init(json: String, status: Int = 200) { result = .success((Data(json.utf8), status)) }
    init(data: Data, status: Int = 200) { result = .success((data, status)) }
    init(error: Error) { result = .failure(error) }

    /// Replays a recorded API exchange: its status code, headers and body.
    init(fixture: APIFixture) {
        result = .success((fixture.body, fixture.statusCode))
        headers = fixture.headers
    }

    func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        let next = queuedResults.isEmpty ? result : queuedResults.removeFirst()
        let (data, status) = try next.get()
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: headers)!
        return (data, response)
    }
}
