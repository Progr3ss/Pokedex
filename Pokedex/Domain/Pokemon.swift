//
//  Pokemon.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation

/// A single Pokémon in the list. This is the domain model the UI and view
struct Pokemon: Identifiable, Equatable, Hashable, Sendable {
    let id: Int
    let name: String
}
