//
//  PokemonListViewModel.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation
import Observation


@MainActor
@Observable
final class PokemonListViewModel {

    /// The screen's loading state. Distinguishing `loading` (first page, full
    /// screen) from `loadingMore` (footer spinner) lets the UI react precisely.
    enum State: Equatable {
        case idle
        case loading
        case loaded
        case loadingMore
        case failed(message: String)
    }

    private(set) var pokemon: [Pokemon] = []
    private(set) var state: State = .idle
    private(set) var totalCount: Int = 0

    /// Cursor for the next page; `nil` once the whole list has been loaded.
    private var nextURL: URL?

    /// Single in-flight guard: prevents duplicate requests while a load runs.
    private var isLoading = false

    private let repository: PokemonRepository
    private let loadMoreThreshold: Int

    /// - Parameter loadMoreThreshold: how many rows from the end should trigger
    ///   the next page fetch (a larger value pre-fetches earlier).
    init(repository: PokemonRepository, loadMoreThreshold: Int = 5) {
        self.repository = repository
        self.loadMoreThreshold = loadMoreThreshold
    }

    var loadedCount: Int { pokemon.count }
    var hasMore: Bool { nextURL != nil }

    /// Loads the first page. No-op if a load is already running.
    func loadInitial() async {
        guard !isLoading else { return }
        isLoading = true
        state = .loading
        defer { isLoading = false }

        do {
            let page = try await repository.loadFirstPage()
            pokemon = page.items
            totalCount = page.totalCount
            nextURL = page.nextURL
            state = .loaded
        } catch {
            state = .failed(message: Self.message(for: error))
        }
    }

    /// Loads the next page. No-op if a load is running or there is no cursor.
    func loadMore() async {
        guard !isLoading, let url = nextURL else { return }
        isLoading = true
        state = .loadingMore
        defer { isLoading = false }

        do {
            let page = try await repository.loadPage(at: url)
            pokemon.append(contentsOf: page.items)
            totalCount = page.totalCount
            nextURL = page.nextURL
            state = .loaded
        } catch {
            state = .failed(message: Self.message(for: error))
        }
    }

    /// Called as rows appear; triggers `loadMore` when the item is within
    /// `loadMoreThreshold` rows of the end.
    func loadMoreIfNeeded(currentItem: Pokemon) async {
        // After a page failure, wait for an explicit retry rather than
        // auto-hammering the failing endpoint as rows re-appear.
        if case .failed = state { return }
        guard let index = pokemon.firstIndex(of: currentItem) else { return }
        let triggerIndex = pokemon.count - 1 - loadMoreThreshold
        guard index >= triggerIndex else { return }
        await loadMore()
    }

    /// Retries whichever load makes sense given current progress.
    func retry() async {
        if pokemon.isEmpty {
            await loadInitial()
        } else {
            await loadMore()
        }
    }

    private static func message(for error: Error) -> String {
        switch error {
        case NetworkError.unacceptableStatusCode(let code):
            return "The server responded with an error (\(code))."
        case NetworkError.transport, is URLError:
            return "Couldn't reach the network. Check your connection and try again."
        default:
            return "Something went wrong. Please try again."
        }
    }
}
