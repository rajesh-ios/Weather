//
//  StubBehavior.swift
//  Weather App
//
//  Created by Banka Rajesh on 10/28/26.
//

#if DEBUG
import Foundation

/// How a stub answers: with a value, with an error, or never (to show loading states).
enum StubBehavior<Value> {
    case success(Value)
    case failure(Error)
    /// Never finishes, so previews can show spinners. Ends only if the task is cancelled.
    case loading

    func resolve() async throws -> Value {
        switch self {
        case .success(let value): return value
        case .failure(let error): throw error
        case .loading:
            try await Task.sleep(nanoseconds: .max)
            throw CancellationError()
        }
    }
}
#endif
