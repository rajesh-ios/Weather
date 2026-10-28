//
//  RetryingHTTPClientTests.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
import Testing
@testable import Weather_App

struct RetryingHTTPClientTests {
    /// Records requested waits instead of sleeping, so tests run instantly.
    final class SleepRecorder {
        var delays: [Duration] = []
        /// When set, the next wait throws this (simulates cancellation mid-backoff).
        var error: Error?
    }

    let request = URLRequest(url: URL(string: "https://api.openweathermap.org/data/2.5/weather")!)
    let sleeper = SleepRecorder()

    private func makeClient(_ mock: MockHTTPClient) -> RetryingHTTPClient {
        RetryingHTTPClient(
            wrapping: mock,
            sleep: { [sleeper] delay in
                sleeper.delays.append(delay)
                if let error = sleeper.error { throw error }
            },
            jitter: { 0 } // deterministic backoff
        )
    }

    private func status(of response: URLResponse) -> Int? {
        (response as? HTTPURLResponse)?.statusCode
    }

    // MARK: - Transient failures are retried

    @Test(arguments: [502, 503, 504])
    func transientServerErrorIsRetriedThenSucceeds(code: Int) async throws {
        let mock = MockHTTPClient(json: "{}")
        mock.queuedResults = [.success((Data(), code))]

        let (_, response) = try await makeClient(mock).perform(request)

        #expect(status(of: response) == 200)
        #expect(mock.requests.count == 2)
        #expect(sleeper.delays == [.seconds(1)])
    }

    @Test func retriesStopAfterMaxWithExponentialBackoff() async throws {
        let mock = MockHTTPClient(json: "{}", status: 503)

        let (_, response) = try await makeClient(mock).perform(request)

        #expect(status(of: response) == 503) // DataStore turns this into WebServiceError.statusCode(503)
        #expect(mock.requests.count == 3)    // 1 attempt + 2 retries
        #expect(sleeper.delays == [.seconds(1), .seconds(2)])
    }

    @Test func droppedConnectionIsRetried() async throws {
        let mock = MockHTTPClient(json: "{}")
        mock.queuedResults = [.failure(URLError(.networkConnectionLost))]

        let (_, response) = try await makeClient(mock).perform(request)

        #expect(status(of: response) == 200)
        #expect(mock.requests.count == 2)
    }

    @Test func jitterIsAddedToBackoff() async throws {
        let mock = MockHTTPClient(json: "{}")
        mock.queuedResults = [.success((Data(), 503))]
        let client = RetryingHTTPClient(
            wrapping: mock,
            sleep: { [sleeper] in sleeper.delays.append($0) },
            jitter: { 0.5 }
        )

        _ = try await client.perform(request)

        #expect(sleeper.delays == [.milliseconds(1250)]) // 1s + 0.5 × 0.5s
    }

    // MARK: - Rate limiting

    @Test func rateLimitHonoursShortRetryAfterOnce() async throws {
        let mock = MockHTTPClient(json: "{}", status: 429)
        mock.headers = ["Retry-After": "2"]

        let (_, response) = try await makeClient(mock).perform(request)

        #expect(status(of: response) == 429) // still limited after one wait → surface the error
        #expect(mock.requests.count == 2)
        #expect(sleeper.delays == [.seconds(2)])
    }

    @Test(arguments: [nil, "60", "soon"])
    func rateLimitWithoutUsableRetryAfterFailsImmediately(retryAfter: String?) async throws {
        let mock = MockHTTPClient(json: "{}", status: 429)
        mock.headers = retryAfter.map { ["Retry-After": $0] } ?? [:]

        _ = try await makeClient(mock).perform(request)

        #expect(mock.requests.count == 1)
        #expect(sleeper.delays.isEmpty)
    }

    // MARK: - Permanent or deliberate failures are not retried

    @Test(arguments: [200, 400, 401, 404, 500])
    func nonTransientStatusIsReturnedAsIs(code: Int) async throws {
        let mock = MockHTTPClient(json: "{}", status: code)

        let (_, response) = try await makeClient(mock).perform(request)

        #expect(status(of: response) == code)
        #expect(mock.requests.count == 1)
    }

    @Test(arguments: [URLError.Code.notConnectedToInternet, .timedOut, .cancelled, .cannotFindHost])
    func nonTransientURLErrorIsThrownImmediately(code: URLError.Code) async {
        let mock = MockHTTPClient(error: URLError(code))

        await #expect(throws: URLError(code)) { try await makeClient(mock).perform(request) }
        #expect(mock.requests.count == 1)
        #expect(sleeper.delays.isEmpty)
    }

    @Test func cancellationDuringBackoffStopsRetrying() async {
        let mock = MockHTTPClient(json: "{}", status: 503)
        sleeper.error = CancellationError()

        await #expect(throws: CancellationError.self) { try await makeClient(mock).perform(request) }
        #expect(mock.requests.count == 1) // no request after the cancelled wait
    }
}
