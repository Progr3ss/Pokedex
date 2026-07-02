//
//  DefaultPokemonRepository.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation

/// Default `PokemonRepository`: fetches bytes via an `HTTPClient`, decodes them
/// into domain pages, and serves/stores pages through a cache. Reads the cache
/// before the network so an already-loaded page is never re-fetched.
final class DefaultPokemonRepository: PokemonRepository {
    private let client: HTTPClient
    private let cache: PokemonPageCaching
    private let config: PokemonAPIConfig
    private let decoder: JSONDecoder

    init(
        client: HTTPClient,
        cache: PokemonPageCaching,
        config: PokemonAPIConfig = .default,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.client = client
        self.cache = cache
        self.config = config
        self.decoder = decoder
    }

    func loadFirstPage() async throws -> PokemonPage {
        try await loadPage(at: config.firstPageURL())
    }

    func loadPage(at url: URL) async throws -> PokemonPage {
        if let cached = await cache.page(for: url) {
            return cached
        }

        let data = try await client.get(from: url)
        let page = try decode(data)
        await cache.insert(page, for: url)
        return page
    }

    private func decode(_ data: Data) throws -> PokemonPage {
        do {
            return try decoder.decode(PokemonListResponseDTO.self, from: data).toDomain()
        } catch {
            throw NetworkError.decoding(underlying: error)
        }
    }
}
