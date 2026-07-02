//
//  PokemonAPIConfig.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation

/// Configuration for the PokéAPI endpoint. Extracted so the base URL and page
/// size are injectable (and thus testable / swappable for other environments).
struct PokemonAPIConfig: Sendable {
    let baseURL: URL
    let pageSize: Int

    static let `default` = PokemonAPIConfig(
        baseURL: URL(string: "https://pokeapi.co/api/v2/pokemon")!,
        pageSize: 10
    )

    /// Builds the first-page URL, e.g. `.../pokemon?limit=10&offset=0`.
    func firstPageURL() -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(pageSize)),
            URLQueryItem(name: "offset", value: "0"),
        ]
        return components.url!
    }
}
