//
//  PokemonMappingTests.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Testing
@testable import Pokedex

@Suite("Pokemon DTO mapping")
struct PokemonMappingTests {

    @Test("extracts the numeric id from the detail URL")
    func extractsIdFromURL() throws {
        let dto = PokemonListItemDTO(
            name: "bulbasaur",
            url: "https://pokeapi.co/api/v2/pokemon/1/"
        )

        let pokemon = try dto.toDomain()

        #expect(pokemon.id == 1)
        #expect(pokemon.name == "bulbasaur")
    }

    @Test("extracts multi-digit ids")
    func extractsMultiDigitId() throws {
        let dto = PokemonListItemDTO(
            name: "wigglytuff",
            url: "https://pokeapi.co/api/v2/pokemon/40/"
        )

        let pokemon = try dto.toDomain()

        #expect(pokemon.id == 40)
    }

    @Test("throws a mapping error when the URL contains no id")
    func throwsWhenIdMissing() {
        let dto = PokemonListItemDTO(
            name: "broken",
            url: "https://pokeapi.co/api/v2/pokemon/"
        )

        #expect(throws: PokemonMappingError.self) {
            try dto.toDomain()
        }
    }
}
