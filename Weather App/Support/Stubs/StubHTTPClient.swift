//
//  StubHTTPClient.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import UIKit

/// HTTP stand-in for `ImageLoader`: returns a drawn icon, fails, or never answers.
struct StubHTTPClient: HTTPClient {
    var behavior: StubBehavior<Data> = .success(Self.iconPNG)

    func perform(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let data = try await behavior.resolve()
        let response = HTTPURLResponse(url: request.url ?? URL(fileURLWithPath: "/"), statusCode: 200, httpVersion: nil, headerFields: nil)
        return (data, response ?? URLResponse())
    }

    /// A simple orange sun, standing in for a downloaded OpenWeather icon.
    static let iconPNG: Data = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100)).pngData { context in
        UIColor.systemOrange.setFill()
        context.cgContext.fillEllipse(in: CGRect(x: 20, y: 20, width: 60, height: 60))
    }
}

extension ImageLoader {
    struct Stubs {
        static var icon: ImageLoader { ImageLoader(client: StubHTTPClient()) }
        static var failing: ImageLoader { ImageLoader(client: StubHTTPClient(behavior: .failure(URLError(.notConnectedToInternet)))) }
        static var loading: ImageLoader { ImageLoader(client: StubHTTPClient(behavior: .loading)) }
    }
}
#endif
