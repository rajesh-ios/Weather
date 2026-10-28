//
//  DataStore.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/**
 Base class for API data stores: sends a `Request` and decodes the JSON response into a data model.
 Feature data stores subclass it (e.g. `OpenWeatherDataStore`) and expose one protocol per API group.
 */
class DataStore {
    private let client: HTTPClient
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase // feels_like → feelsLike
        return decoder
    }()

    /**
     - Parameter client: Performs the HTTP call. `URLSession` in the app, a mock in tests.
     */
    init(client: HTTPClient) {
        self.client = client
    }

    /**
     Sends the request and decodes the response body.
     - Throws: `WebServiceError` for bad URLs or non-2xx responses, `URLError` for transport
       failures, `DecodingError` when the JSON doesn't match `Model`.
     */
    func send<Model: Decodable>(request: Request) async throws -> Model {
        let data = try await client.validatedData(for: request.urlRequest())
        return try decoder.decode(Model.self, from: data)
    }
}
