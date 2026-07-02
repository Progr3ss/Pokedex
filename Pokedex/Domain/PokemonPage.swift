//
//  PokemonPage.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation

/// One page of results from the paginated Pokémon list.
/// `nextURL` is the cursor for loading the following page; `nil` means the
/// end of the list has been reached.
struct PokemonPage: Equatable, Sendable {
    let items: [Pokemon]
    let nextURL: URL?
    let totalCount: Int

    var hasMore: Bool { nextURL != nil }
}
