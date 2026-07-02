//
//  PokemonPageCaching.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation


protocol PokemonPageCaching: Sendable {
    func page(for url: URL) async -> PokemonPage?
    func insert(_ page: PokemonPage, for url: URL) async
}

/// Convenience alias for the concrete in-memory page cache used by the app.
typealias InMemoryPokemonPageCache = InMemoryCache<URL, PokemonPage>

extension InMemoryCache: PokemonPageCaching where Key == URL, Value == PokemonPage {
    func page(for url: URL) async -> PokemonPage? {
        read(url)
    }

    func insert(_ page: PokemonPage, for url: URL) async {
        write(page, for: url)
    }
}
