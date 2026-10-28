//
//  RetryingHTTPClient.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation
import OSLog

/**
 When an `HTTPClient` request should be tried again, and how long to wait.
 Only failures likely to clear on their own are retried; everything else fails immediately.
 Only safe for repeatable requests (GET), which is all this app sends.
 */
struct RetryPolicy {
    /** Retries after the first attempt for transient failures (3 attempts total). */
    var maxRetries = 2

    /** First backoff delay in seconds; doubles per retry (1s, 2s). */
    var baseDelay: TimeInterval = 1

    /** Longest `Retry-After` (429) we're willing to wait behind a spinner; longer → fail and show the error. */
    var maxRetryAfter: Duration = .seconds(5)

    /** Server errors that are usually brief (bad gateway, unavailable, gateway timeout). */
    static let transientStatusCodes: Set<Int> = [502, 503, 504]

    /**
     Transport errors worth retrying. Deliberately excluded:
     - `.notConnectedToInternet`: fails instantly while offline; recovery waits for `NetworkMonitor` instead.
     - `.timedOut`: each attempt already waited 15s; retrying would keep the spinner up ~45s.
     - `.cancelled`: the request was replaced on purpose.
     */
    static let transientURLErrors: Set<URLError.Code> = [.networkConnectionLost]
}

/**
 Decorator that adds automatic retries with exponential backoff to any `HTTPClient`.
 Wraps the client in `AppDependencies`, so data stores and repositories get the policy
 without knowing about it.
 */
final class RetryingHTTPClient: HTTPClient {
    private let client: HTTPClient
    private let policy: RetryPolicy
    /**
     Injected so tests run instantly and can simulate cancellation during a wait.

     - Note: Workaround: `@concurrent` is required. With this project's approachable-concurrency
       setting, a plain async closure type is `nonisolated(nonsending)`, and passing a main-actor
       closure (as the tests do) through that type delivered a corrupted `Duration`
       (~187 billion seconds; caught by RetryingHTTPClientTests). `@concurrent` uses the
       classic calling convention and behaves correctly. Revisit on a newer Swift toolchain.
     */
    private let sleep: @concurrent (Duration) async throws -> Void
    /** 0..<1; spreads retries so many devices don't hit the server at the same moment. */
    private let jitter: () -> Double

    init(
        wrapping client: HTTPClient,
        policy: RetryPolicy = RetryPolicy(),
        sleep: @escaping @concurrent (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
        jitter: @escaping () -> Double = { Double.random(in: 0..<1) }
    ) {
        self.client = client
        self.policy = policy
        self.sleep = sleep
        self.jitter = jitter
    }

    func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        var retries = 0
        while true {
            let delay: Duration
            do {
                let (data, response) = try await client.perform(request)
                guard let next = retryDelay(for: response, retries: retries) else { return (data, response) }
                delay = next
            } catch {
                guard let next = retryDelay(for: error, retries: retries) else { throw error }
                delay = next
            }

            retries += 1
            Logger.network.info("Retrying \(request.url?.path ?? "", privacy: .public) (retry \(retries)) in \(delay.components.seconds)s")
            // Throws CancellationError if the request is cancelled while waiting, which ends the loop.
            try await sleep(delay)
        }
    }

    // MARK: - Policy

    private func retryDelay(for response: URLResponse, retries: Int) -> Duration? {
        guard let http = response as? HTTPURLResponse else { return nil }

        if RetryPolicy.transientStatusCodes.contains(http.statusCode) {
            return backoff(retries: retries)
        }
        // 429: honour the server's Retry-After once, if it's short; otherwise surface the error.
        if http.statusCode == 429, retries == 0,
           let seconds = http.value(forHTTPHeaderField: "Retry-After").flatMap(Int.init),
           seconds >= 0, .seconds(seconds) <= policy.maxRetryAfter {
            return .seconds(seconds)
        }
        return nil
    }

    private func retryDelay(for error: Error, retries: Int) -> Duration? {
        guard let code = (error as? URLError)?.code, RetryPolicy.transientURLErrors.contains(code) else { return nil }
        return backoff(retries: retries)
    }

    /** baseDelay × 2^retries, plus up to half a baseDelay of jitter; nil once retries are used up. */
    private func backoff(retries: Int) -> Duration? {
        guard retries < policy.maxRetries else { return nil }
        // Computed in plain seconds: `Duration * Double` produced wildly wrong values (caught by
        // RetryingHTTPClientTests), so the Double math stays in TimeInterval.
        let seconds = policy.baseDelay * Double(1 << retries) + policy.baseDelay * jitter() / 2
        return .seconds(seconds)
    }
}
