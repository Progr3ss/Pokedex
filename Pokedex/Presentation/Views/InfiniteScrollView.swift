//
//  InfiniteScrollView.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import SwiftUI


/// Reuse it with any `Identifiable` collection by supplying a different `row`.
struct InfiniteScrollView<Item: Identifiable, Row: View>: View {
    let items: [Item]
    let isLoadingMore: Bool
    let hasMore: Bool
    /// A footer-level error (a page failed to load); shows an inline retry.
    let footerErrorMessage: String?
    /// Called from each row's `onAppear`; the caller decides if it triggers a load.
    let onItemAppear: (Item) -> Void
    let onRetry: () -> Void
    @ViewBuilder let row: (Item) -> Row

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    row(item)
                        .transition(insertionTransition)
                        .onAppear { onItemAppear(item) }
                }

                footer
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .animation(reduceMotion ? nil : .spring(duration: 0.35), value: items.count)
        }
    }

    private var insertionTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity
              )
    }

    @ViewBuilder
    private var footer: some View {
        if let message = footerErrorMessage {
            FooterErrorView(message: message, onRetry: onRetry)
        } else if isLoadingMore {
            LoadingFooter()
        } else if !hasMore && !items.isEmpty {
            Text("That's every Pokémon!")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.vertical, 16)
                .accessibilityLabel("End of list. That's every Pokémon.")
        }
    }
}

/// Animated loading indicator shown in the footer while paging.
private struct LoadingFooter: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text("Loading more…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading more Pokémon")
    }
}

private struct FooterErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry", action: onRetry)
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

// MARK: - Reuse demonstration

/// A non-Pokémon model used only to prove `InfiniteScrollView` is generic.
private struct PreviewFruit: Identifiable {
    let id: Int
    let name: String
}

/// Proves the component is genuinely generic: it drives a non-Pokémon model
/// with zero changes to `InfiniteScrollView`.
#Preview("Reused with a different model") {
    InfiniteScrollView(
        items: [
            PreviewFruit(id: 1, name: "Apple"),
            PreviewFruit(id: 2, name: "Banana"),
            PreviewFruit(id: 3, name: "Cherry"),
        ],
        isLoadingMore: true,
        hasMore: true,
        footerErrorMessage: nil,
        onItemAppear: { _ in },
        onRetry: {},
        row: { fruit in
            Text(fruit.name)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        }
    )
}
