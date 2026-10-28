//
//  APIFixture.swift
//  Weather AppTests
//
//  Created by Banka Rajesh on 10/28/26.
//

import Foundation

/**
 One API exchange stored as JSON in `Fixtures/API/<Endpoint>/<name>.json`: the request that was
 sent and the response that came back (status, headers, body).

 Fixtures marked "recorded" are real OpenWeather responses; "synthetic" ones cover cases the
 live API can't produce on demand (rate limits, outages, malformed bodies). The `appid` in
 request URLs is redacted to `{API_KEY}`.
 */
struct APIFixture {
    let name: String
    let description: String
    /// Request URL as recorded, with `appid={API_KEY}`.
    let requestURL: URL
    let statusCode: Int
    let headers: [String: String]
    /// Response body bytes: the JSON `body`, or the raw `bodyText` for non-JSON responses.
    let body: Data

    /// Query items of the recorded request, excluding the redacted `appid`.
    var requestQuery: [String: String] {
        let items = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(items.filter { $0.name != "appid" }.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { $1 })
    }

    /// Loads `name.json` from the test bundle. A missing or malformed fixture stops the test run:
    /// that's a broken test setup, not a test failure.
    static func load(_ name: String) -> APIFixture {
        guard let url = fixtureURL(named: name) else {
            fatalError("Fixture \(name).json not found in the test bundle")
        }
        do {
            let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any] ?? [:]
            let request = json["request"] as? [String: Any] ?? [:]
            let response = json["response"] as? [String: Any] ?? [:]

            let body: Data
            if let text = response["bodyText"] as? String {
                body = Data(text.utf8)
            } else {
                body = try JSONSerialization.data(withJSONObject: response["body"] ?? NSNull(), options: [.fragmentsAllowed])
            }

            // `{API_KEY}` isn't valid in a URL, so swap it for a placeholder before parsing.
            let urlString = (request["url"] as? String ?? "").replacingOccurrences(of: "{API_KEY}", with: "API_KEY")
            guard let requestURL = URL(string: urlString), let statusCode = response["statusCode"] as? Int else {
                fatalError("Fixture \(name).json is missing request.url or response.statusCode")
            }
            return APIFixture(
                name: name,
                description: json["description"] as? String ?? "",
                requestURL: requestURL,
                statusCode: statusCode,
                headers: response["headers"] as? [String: String] ?? [:],
                body: body
            )
        } catch {
            fatalError("Fixture \(name).json couldn't be read: \(error)")
        }
    }

    /// Xcode may copy fixtures flat or keep their folders, so search the whole bundle.
    private static func fixtureURL(named name: String) -> URL? {
        let bundle = Bundle(for: BundleToken.self)
        if let flat = bundle.url(forResource: name, withExtension: "json") { return flat }
        guard let root = bundle.resourceURL,
              let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        else { return nil }
        return files.lazy.compactMap { $0 as? URL }.first { $0.lastPathComponent == "\(name).json" }
    }
}

private final class BundleToken {}
