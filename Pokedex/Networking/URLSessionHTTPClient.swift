//
//  URLSessionHTTPClient.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation

/// `URLSession`-backed `HTTPClient`. No third-party dependencies; uses Swift
/// Concurrency. Validates that the response is HTTP with a 2xx status and maps
/// everything else onto `NetworkError`.
final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL) async throws -> Data {
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            guard (200..<300).contains(http.statusCode) else {
                throw NetworkError.unacceptableStatusCode(http.statusCode)
            }
            return data
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.transport(underlying: error)
        }
    }
}
