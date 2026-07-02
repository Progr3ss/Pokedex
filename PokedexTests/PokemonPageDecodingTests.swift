//
//  PokemonPageDecodingTests.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation
import Testing
@testable import Pokedex

@Suite("Pokemon page decoding")
struct PokemonPageDecodingTests {

    @Test("decodes a page and maps items, next cursor, and total count")
    func decodesPage() throws {
        let json = Data("""
        {
          "count": 1302,
          "next": "https://pokeapi.co/api/v2/pokemon?offset=10&limit=10",
          "previous": null,
          "results": [
            { "name": "bulbasaur", "url": "https://pokeapi.co/api/v2/pokemon/1/" },
            { "name": "ivysaur", "url": "https://pokeapi.co/api/v2/pokemon/2/" }
          ]
        }
        """.utf8)

        let dto = try JSONDecoder().decode(PokemonListResponseDTO.self, from: json)
        let page = try dto.toDomain()

        #expect(page.totalCount == 1302)
        #expect(page.items == [
            Pokemon(id: 1, name: "bulbasaur"),
            Pokemon(id: 2, name: "ivysaur"),
        ])
        #expect(page.nextURL == URL(string: "https://pokeapi.co/api/v2/pokemon?offset=10&limit=10"))
    }

    @Test("a null next field maps to no further pages")
    func nullNextMeansNoMorePages() throws {
        let json = Data("""
        {
          "count": 1302,
          "next": null,
          "previous": "https://pokeapi.co/api/v2/pokemon?offset=1290&limit=10",
          "results": [
            { "name": "iron-leaves", "url": "https://pokeapi.co/api/v2/pokemon/1302/" }
          ]
        }
        """.utf8)

        let dto = try JSONDecoder().decode(PokemonListResponseDTO.self, from: json)
        let page = try dto.toDomain()

        #expect(page.nextURL == nil)
        #expect(page.hasMore == false)
    }
}
