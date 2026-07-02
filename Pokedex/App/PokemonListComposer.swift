//
//  PokemonListComposer.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation

/// Composition root: the single place where concrete dependencies are wired
/// together. 
enum PokemonListComposer {
    @MainActor
    static func makeListView() -> PokemonListView {
        let client = URLSessionHTTPClient()
        let cache = InMemoryPokemonPageCache()
        let repository = DefaultPokemonRepository(client: client, cache: cache)
        let viewModel = PokemonListViewModel(repository: repository)
        return PokemonListView(viewModel: viewModel)
    }
}
