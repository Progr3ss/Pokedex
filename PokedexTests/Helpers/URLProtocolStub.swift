//
//  URLProtocolStub.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation

/// A `URLProtocol` that intercepts requests so networking can be tested
final class URLProtocolStub: URLProtocol {

    struct Stub {
        let data: Data?
        let response: URLResponse?
        let error: Error?
    }

    private static let queue = DispatchQueue(label: "URLProtocolStub.queue")
    nonisolated(unsafe) private static var _stub: Stub?
    nonisolated(unsafe) private static var _requestedURLs: [URL] = []

    static func stub(data: Data?, response: URLResponse?, error: Error?) {
        queue.sync { _stub = Stub(data: data, response: response, error: error) }
    }

    static func reset() {
        queue.sync {
            _stub = nil
            _requestedURLs = []
        }
    }

    static var requestedURLs: [URL] {
        queue.sync { _requestedURLs }
    }

    /// Builds an ephemeral session wired to this stub.
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: config)
    }

    static func makeHTTPResponse(url: URL, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    // MARK: URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let url = request.url {
            Self.queue.sync { Self._requestedURLs.append(url) }
        }
        let stub = Self.queue.sync { Self._stub }

        if let error = stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        if let response = stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data = stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
