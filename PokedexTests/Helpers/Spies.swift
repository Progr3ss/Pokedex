//
//  Spies.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation
@testable import Pokedex

/// Records the URLs it is asked to fetch and returns a canned response or error.
/// An actor so it is safely `Sendable` under strict concurrency.
actor HTTPClientSpy: HTTPClient {
    private var stubbedData: Data = Data()
    private var stubbedError: Error?
    private(set) var requestedURLs: [URL] = []

    func get(from url: URL) async throws -> Data {
        requestedURLs.append(url)
        if let stubbedError { throw stubbedError }
        return stubbedData
    }

    func stub(data: Data) { stubbedData = data }
    func stub(error: Error) { stubbedError = error }
}

/// A cache spy that records inserts and lets tests preload entries.
actor PokemonPageCacheSpy: PokemonPageCaching {
    private var storage: [URL: PokemonPage] = [:]
    private(set) var insertedURLs: [URL] = []
    private(set) var readURLs: [URL] = []

    func page(for url: URL) async -> PokemonPage? {
        readURLs.append(url)
        return storage[url]
    }

    func insert(_ page: PokemonPage, for url: URL) async {
        storage[url] = page
        insertedURLs.append(url)
    }

    /// Test-only seeding that does not count as an "insert".
    func preload(_ page: PokemonPage, for url: URL) {
        storage[url] = page
    }
}

enum TestData {
    static func pageJSON(next: String?, names: [(Int, String)]) -> Data {
        let results = names
            .map { "{ \"name\": \"\($0.1)\", \"url\": \"https://pokeapi.co/api/v2/pokemon/\($0.0)/\" }" }
            .joined(separator: ",")
        let nextValue = next.map { "\"\($0)\"" } ?? "null"
        return Data("""
        { "count": 1302, "next": \(nextValue), "previous": null, "results": [\(results)] }
        """.utf8)
    }
}
