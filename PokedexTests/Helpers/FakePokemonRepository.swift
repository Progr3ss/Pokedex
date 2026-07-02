//
//  FakePokemonRepository.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation
@testable import Pokedex

enum TestError: Error { case boom }

/// A fully controllable `PokemonRepository` fake for view-model tests.
/// An actor, so calls are serialized and it is `Sendable`. Every call is a
/// suspension point, which lets tests exercise concurrent-call de-duplication
/// deterministically.
actor FakePokemonRepository: PokemonRepository {
    private var firstPageResult: Result<PokemonPage, Error>
    private var pageResults: [URL: Result<PokemonPage, Error>] = [:]

    private(set) var firstPageCallCount = 0
    private(set) var requestedPageURLs: [URL] = []

    init(firstPage: Result<PokemonPage, Error> = .success(TestFixtures.page(ids: [1], next: nil))) {
        self.firstPageResult = firstPage
    }

    func loadFirstPage() async throws -> PokemonPage {
        firstPageCallCount += 1
        return try firstPageResult.get()
    }

    func loadPage(at url: URL) async throws -> PokemonPage {
        requestedPageURLs.append(url)
        guard let result = pageResults[url] else { throw TestError.boom }
        return try result.get()
    }

    func setFirstPage(_ result: Result<PokemonPage, Error>) { firstPageResult = result }
    func setPage(_ result: Result<PokemonPage, Error>, for url: URL) { pageResults[url] = result }
}

enum TestFixtures {
    static func page(ids: [Int], next: String?, totalCount: Int = 1302) -> PokemonPage {
        PokemonPage(
            items: ids.map { Pokemon(id: $0, name: "pokemon-\($0)") },
            nextURL: next.flatMap { URL(string: $0) },
            totalCount: totalCount
        )
    }
}
