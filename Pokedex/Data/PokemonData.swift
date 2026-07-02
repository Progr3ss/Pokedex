//
//  PokemonData.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation

/// Error thrown when a wire-format DTO cannot be mapped to a domain model.
enum PokemonMappingError: Error, Equatable {
    case missingID(url: String)
}

/// Wire-format model for a single item in the `/pokemon` list response.
/// The API only gives us a `name` and a detail `url`; 
struct PokemonListItemDTO: Decodable, Sendable, Equatable {
    let name: String
    let url: String

    func toDomain() throws -> Pokemon {
        guard let id = Self.extractID(from: url) else {
            throw PokemonMappingError.missingID(url: url)
        }
        return Pokemon(id: id, name: name)
    }

    /// Pulls the trailing numeric path component out of a detail URL.
    static func extractID(from url: String) -> Int? {
        url.split(separator: "/")
            .last
            .flatMap { Int($0) }
    }
}

/// Wire-format model for the whole `/pokemon` list response.
struct PokemonListResponseDTO: Decodable, Sendable, Equatable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [PokemonListItemDTO]

    func toDomain() throws -> PokemonPage {
        let items = try results.map { try $0.toDomain() }
        return PokemonPage(
            items: items,
            nextURL: next.flatMap { URL(string: $0) },
            totalCount: count
        )
    }
}
