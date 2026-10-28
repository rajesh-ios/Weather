//
//  ImageLoader.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/27/26.
//

import UIKit

/// Downloads and caches weather icons.
/// Two layers: this in-memory `NSCache` (decoded images, evicted under memory pressure)
/// and the session's `URLCache` (raw bytes on disk, survives relaunch).
final class ImageLoader {
    enum LoaderError: Error { case invalidImageData }

    private let client: HTTPClient
    private let cache = NSCache<NSURL, UIImage>()
    /// De-duplicates concurrent requests for the same URL (e.g. during rotation re-renders).
    private var inFlight: [URL: Task<UIImage, Error>] = [:]

    init(client: HTTPClient) {
        self.client = client
        cache.countLimit = 100 // ~50 distinct OpenWeather icons exist, so this never evicts in practice.
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = cache.object(forKey: url as NSURL) { return cached }
        if let pending = inFlight[url] { return try await pending.value }

        let task = Task {
            let data = try await client.validatedData(for: URLRequest(url: url))
            // Move to a detached task if large images are ever loaded through here.
            guard let image = UIImage(data: data) else { throw LoaderError.invalidImageData }
            return image
        }
        inFlight[url] = task
        defer { inFlight[url] = nil }

        let image = try await task.value
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
