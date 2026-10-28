//
//  HTTPClient.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import Foundation
import OSLog

/// Minimal networking seam so data stores can be unit-tested without hitting the network.
protocol HTTPClient {
    func perform(_ request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPClient {
    func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }
}

extension HTTPClient {
    /// Performs the request and returns the body only for 2xx responses.
    /// Used by `DataStore` for JSON and by `ImageLoader` for icon bytes.
    func validatedData(for request: URLRequest) async throws -> Data {
        // Only the path is logged: the query string carries the API key.
        let path = request.url?.path ?? ""
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await perform(request)
        } catch {
            Logger.network.error("\(request.httpMethod ?? "GET", privacy: .public) \(path, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
        guard let http = response as? HTTPURLResponse else { throw WebServiceError.serverResponse }
        Logger.network.debug("\(request.httpMethod ?? "GET", privacy: .public) \(path, privacy: .public) → \(http.statusCode)")
        guard (200..<300).contains(http.statusCode) else {
            throw WebServiceError.statusCode(http.statusCode)
        }
        return data
    }
}
