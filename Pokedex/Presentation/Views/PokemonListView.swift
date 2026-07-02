//
//  PokemonListView.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import SwiftUI

/// The Pokémon list screen. Owns the view model and maps its state onto the
/// reusable `InfiniteScrollView`
struct PokemonListView: View {
    @State private var viewModel: PokemonListViewModel

    init(viewModel: PokemonListViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pokédex")
                .font(.largeTitle.bold())
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .accessibilityAddTraits(.isHeader)

            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task {
            if viewModel.state == .idle {
                await viewModel.loadInitial()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.pokemon.isEmpty {
            switch viewModel.state {
            case .failed(let message):
                ErrorStateView(message: message) {
                    Task { await viewModel.retry() }
                }
                .frame(maxHeight: .infinity)
            default:
                skeletonList
            }
        } else {
            loadedList
        }
    }

    private var loadedList: some View {
        VStack(spacing: 12) {
            LoadedCountHeader(count: viewModel.loadedCount)

            InfiniteScrollView(
                items: viewModel.pokemon,
                isLoadingMore: viewModel.state == .loadingMore,
                hasMore: viewModel.hasMore,
                footerErrorMessage: footerErrorMessage,
                onItemAppear: { item in
                    Task { await viewModel.loadMoreIfNeeded(currentItem: item) }
                },
                onRetry: {
                    Task { await viewModel.retry() }
                },
                row: { pokemon in
                    PokemonRow(pokemon: pokemon)
                }
            )
        }
    }

    private var skeletonList: some View {
        VStack(spacing: 12) {
            LoadedCountHeader(count: 0)
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(0..<8, id: \.self) { _ in
                        SkeletonRow()
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .accessibilityLabel("Loading Pokémon")
    }

    /// A page-level failure surfaces as an inline footer retry only when we
    /// already have content to keep on screen.
    private var footerErrorMessage: String? {
        if case .failed(let message) = viewModel.state, !viewModel.pokemon.isEmpty {
            return message
        }
        return nil
    }
}
