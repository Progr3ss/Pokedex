//
//  URLSessionHTTPClientTests.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation
import Testing
@testable import Pokedex

@Suite("URLSessionHTTPClient", .serialized)
struct URLSessionHTTPClientTests {

    private let url = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=10&offset=0")!

    init() { URLProtocolStub.reset() }

    @Test("returns data on a 200 response")
    func returnsDataOn200() async throws {
        let expected = Data("hello".utf8)
        URLProtocolStub.stub(
            data: expected,
            response: URLProtocolStub.makeHTTPResponse(url: url, statusCode: 200),
            error: nil
        )
        let sut = URLSessionHTTPClient(session: URLProtocolStub.makeSession())

        let data = try await sut.get(from: url)

        #expect(data == expected)
        #expect(URLProtocolStub.requestedURLs == [url])
    }

    @Test("throws unacceptableStatusCode on a 500 response")
    func throwsOn500() async {
        URLProtocolStub.stub(
            data: Data(),
            response: URLProtocolStub.makeHTTPResponse(url: url, statusCode: 500),
            error: nil
        )
        let sut = URLSessionHTTPClient(session: URLProtocolStub.makeSession())

        await #expect(throws: NetworkError.unacceptableStatusCode(500)) {
            _ = try await sut.get(from: url)
        }
    }

    @Test("wraps a transport error as NetworkError.transport")
    func wrapsTransportError() async {
        let underlying = URLError(.notConnectedToInternet)
        URLProtocolStub.stub(data: nil, response: nil, error: underlying)
        let sut = URLSessionHTTPClient(session: URLProtocolStub.makeSession())

        await #expect(throws: NetworkError.self) {
            _ = try await sut.get(from: url)
        }
    }
}
