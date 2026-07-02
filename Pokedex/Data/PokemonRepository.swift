//
//  PokemonRepository.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation


protocol PokemonRepository: Sendable {
    /// Loads the first page of the list.
    func loadFirstPage() async throws -> PokemonPage
    /// Loads the page addressed by a cursor URL (the `next` from a prior page).
    func loadPage(at url: URL) async throws -> PokemonPage
}
