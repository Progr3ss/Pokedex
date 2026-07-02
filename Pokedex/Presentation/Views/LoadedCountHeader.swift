//
//  LoadedCountHeader.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import SwiftUI

/// Shows the running count of loaded Pokémon. The number animates on change via
/// a numeric content transition (state-driven, no manual animation bookkeeping).
struct LoadedCountHeader: View {
    let count: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("Loaded Pokémon")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .contentTransition(.numericText())
                .animation(.snappy, value: count)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loaded \(count) Pokémon")
    }
}

/// Full-screen error shown when the very first page fails (nothing to display).
struct ErrorStateView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
    }
}
