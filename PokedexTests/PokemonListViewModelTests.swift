//
//  PokemonListViewModelTests.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation
import Testing
@testable import Pokedex

@MainActor
@Suite("PokemonListViewModel")
struct PokemonListViewModelTests {

    private let page2URL = "https://pokeapi.co/api/v2/pokemon?offset=10&limit=10"
    private let page3URL = "https://pokeapi.co/api/v2/pokemon?offset=20&limit=10"

    // MARK: Initial state

    @Test("starts idle and empty")
    func startsIdle() {
        let sut = PokemonListViewModel(repository: FakePokemonRepository())
        #expect(sut.state == .idle)
        #expect(sut.pokemon.isEmpty)
        #expect(sut.loadedCount == 0)
        #expect(sut.hasMore == false)
    }

    // MARK: Initial load

    @Test("loadInitial populates items and moves to loaded")
    func loadInitialSuccess() async {
        let repo = FakePokemonRepository(firstPage: .success(
            TestFixtures.page(ids: [1, 2], next: page2URL)
        ))
        let sut = PokemonListViewModel(repository: repo)

        await sut.loadInitial()

        #expect(sut.pokemon == [Pokemon(id: 1, name: "pokemon-1"), Pokemon(id: 2, name: "pokemon-2")])
        #expect(sut.state == .loaded)
        #expect(sut.loadedCount == 2)
        #expect(sut.totalCount == 1302)
        #expect(sut.hasMore == true)
    }

    @Test("loadInitial failure moves to failed and leaves items empty")
    func loadInitialFailure() async {
        let repo = FakePokemonRepository(firstPage: .failure(TestError.boom))
        let sut = PokemonListViewModel(repository: repo)

        await sut.loadInitial()

        #expect(sut.pokemon.isEmpty)
        if case .failed = sut.state {} else {
            Issue.record("expected failed state, got \(sut.state)")
        }
    }

    // MARK: Pagination

    @Test("loadMore appends the next page and advances the cursor")
    func loadMoreAppends() async {
        let repo = FakePokemonRepository(firstPage: .success(
            TestFixtures.page(ids: [1, 2], next: page2URL)
        ))
        await repo.setPage(.success(TestFixtures.page(ids: [3, 4], next: page3URL)),
                           for: URL(string: page2URL)!)
        let sut = PokemonListViewModel(repository: repo)
        await sut.loadInitial()

        await sut.loadMore()

        #expect(sut.pokemon.map(\.id) == [1, 2, 3, 4])
        #expect(sut.state == .loaded)
        #expect(sut.hasMore == true) // page3URL still pending
    }

    @Test("reaching the last page clears hasMore")
    func lastPageClearsHasMore() async {
        let repo = FakePokemonRepository(firstPage: .success(
            TestFixtures.page(ids: [1], next: page2URL)
        ))
        await repo.setPage(.success(TestFixtures.page(ids: [2], next: nil)),
                           for: URL(string: page2URL)!)
        let sut = PokemonListViewModel(repository: repo)
        await sut.loadInitial()

        await sut.loadMore()

        #expect(sut.hasMore == false)
    }

    @Test("loadMore with no next cursor does nothing")
    func loadMoreWithoutCursorIsNoOp() async {
        let repo = FakePokemonRepository(firstPage: .success(
            TestFixtures.page(ids: [1], next: nil)
        ))
        let sut = PokemonListViewModel(repository: repo)
        await sut.loadInitial()

        await sut.loadMore()

        #expect(await repo.requestedPageURLs.isEmpty)
    }

    // MARK: De-duplication

    @Test("concurrent loadMore calls trigger only a single fetch")
    func concurrentLoadMoreDeduplicated() async {
        let repo = FakePokemonRepository(firstPage: .success(
            TestFixtures.page(ids: [1], next: page2URL)
        ))
        await repo.setPage(.success(TestFixtures.page(ids: [2], next: page3URL)),
                           for: URL(string: page2URL)!)
        let sut = PokemonListViewModel(repository: repo)
        await sut.loadInitial()

        async let first: Void = sut.loadMore()
        async let second: Void = sut.loadMore()
        _ = await (first, second)

        #expect(await repo.requestedPageURLs == [URL(string: page2URL)!])
    }

    // MARK: Threshold-driven loading

    @Test("loadMoreIfNeeded fetches when the item is near the end")
    func loadMoreIfNeededNearEnd() async {
        let repo = FakePokemonRepository(firstPage: .success(
            TestFixtures.page(ids: Array(1...10), next: page2URL)
        ))
        await repo.setPage(.success(TestFixtures.page(ids: [11], next: nil)),
                           for: URL(string: page2URL)!)
        let sut = PokemonListViewModel(repository: repo, loadMoreThreshold: 3)
        await sut.loadInitial()

        await sut.loadMoreIfNeeded(currentItem: sut.pokemon.last!)

        #expect(await repo.requestedPageURLs == [URL(string: page2URL)!])
    }

    @Test("loadMoreIfNeeded does not fetch for an item far from the end")
    func loadMoreIfNeededFarFromEnd() async {
        let repo = FakePokemonRepository(firstPage: .success(
            TestFixtures.page(ids: Array(1...10), next: page2URL)
        ))
        let sut = PokemonListViewModel(repository: repo, loadMoreThreshold: 3)
        await sut.loadInitial()

        await sut.loadMoreIfNeeded(currentItem: sut.pokemon.first!)

        #expect(await repo.requestedPageURLs.isEmpty)
    }

    @Test("after a page failure, scrolling does not auto-retry until explicit retry")
    func noAutoRetryAfterFailure() async {
        let repo = FakePokemonRepository(firstPage: .success(
            TestFixtures.page(ids: Array(1...10), next: page2URL)
        ))
        await repo.setPage(.failure(TestError.boom), for: URL(string: page2URL)!)
        let sut = PokemonListViewModel(repository: repo, loadMoreThreshold: 3)
        await sut.loadInitial()

        // First near-end appearance triggers a load that fails.
        await sut.loadMoreIfNeeded(currentItem: sut.pokemon.last!)
        // Subsequent appearances must NOT keep hammering the failing endpoint.
        await sut.loadMoreIfNeeded(currentItem: sut.pokemon.last!)
        await sut.loadMoreIfNeeded(currentItem: sut.pokemon.last!)

        #expect(await repo.requestedPageURLs == [URL(string: page2URL)!])
    }

    // MARK: Retry

    @Test("retry after an initial failure recovers to loaded")
    func retryRecovers() async {
        let repo = FakePokemonRepository(firstPage: .failure(TestError.boom))
        let sut = PokemonListViewModel(repository: repo)
        await sut.loadInitial()

        await repo.setFirstPage(.success(TestFixtures.page(ids: [1], next: nil)))
        await sut.retry()

        #expect(sut.pokemon.map(\.id) == [1])
        #expect(sut.state == .loaded)
    }
}
