//
//  MainPokemonRepositoryTests.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation
import Testing
@testable import Pokedex

@Suite("MainPokemonRepository")
struct MianPokemonRepositoryTests {

    private let firstPageURL = URL(string: "https://pokeapi.co/api/v2/pokemon?limit=10&offset=0")!

    private func makeSUT(
        client: HTTPClientSpy = HTTPClientSpy(),
        cache: PokemonPageCacheSpy = PokemonPageCacheSpy()
    ) -> DefaultPokemonRepository {
        DefaultPokemonRepository(client: client, cache: cache, config: .default)
    }

    @Test("loadFirstPage requests the correctly-built first-page URL")
    func loadFirstPageBuildsURL() async throws {
        let client = HTTPClientSpy()
        await client.stub(data: TestData.pageJSON(next: nil, names: [(1, "bulbasaur")]))
        let sut = makeSUT(client: client)

        _ = try await sut.loadFirstPage()

        #expect(await client.requestedURLs == [firstPageURL])
    }

    @Test("loadFirstPage decodes the response into a domain page")
    func loadFirstPageDecodes() async throws {
        let client = HTTPClientSpy()
        await client.stub(data: TestData.pageJSON(
            next: "https://pokeapi.co/api/v2/pokemon?offset=10&limit=10",
            names: [(1, "bulbasaur"), (2, "ivysaur")]
        ))
        let sut = makeSUT(client: client)

        let page = try await sut.loadFirstPage()

        #expect(page.items == [Pokemon(id: 1, name: "bulbasaur"), Pokemon(id: 2, name: "ivysaur")])
        #expect(page.nextURL == URL(string: "https://pokeapi.co/api/v2/pokemon?offset=10&limit=10"))
    }

    @Test("loadPage(at:) fetches the given cursor URL")
    func loadPageAtCursor() async throws {
        let cursor = URL(string: "https://pokeapi.co/api/v2/pokemon?offset=10&limit=10")!
        let client = HTTPClientSpy()
        await client.stub(data: TestData.pageJSON(next: nil, names: [(11, "metapod")]))
        let sut = makeSUT(client: client)

        _ = try await sut.loadPage(at: cursor)

        #expect(await client.requestedURLs == [cursor])
    }

    @Test("a cached page is returned without hitting the network")
    func cacheHitSkipsNetwork() async throws {
        let cache = PokemonPageCacheSpy()
        let cached = PokemonPage(items: [Pokemon(id: 1, name: "bulbasaur")], nextURL: nil, totalCount: 1302)
        await cache.preload(cached, for: firstPageURL)
        let client = HTTPClientSpy()
        let sut = makeSUT(client: client, cache: cache)

        let page = try await sut.loadFirstPage()

        #expect(page == cached)
        #expect(await client.requestedURLs.isEmpty)
    }

    @Test("a freshly fetched page is written to the cache")
    func cacheMissStoresResult() async throws {
        let client = HTTPClientSpy()
        await client.stub(data: TestData.pageJSON(next: nil, names: [(1, "bulbasaur")]))
        let cache = PokemonPageCacheSpy()
        let sut = makeSUT(client: client, cache: cache)

        _ = try await sut.loadFirstPage()

        #expect(await cache.insertedURLs == [firstPageURL])
    }

    @Test("invalid JSON is surfaced as NetworkError.decoding")
    func decodingErrorMapped() async {
        let client = HTTPClientSpy()
        await client.stub(data: Data("not json".utf8))
        let sut = makeSUT(client: client)

        await #expect(throws: NetworkError.self) {
            _ = try await sut.loadFirstPage()
        }
    }
}
