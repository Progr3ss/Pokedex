//
//  PokemonRow.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import SwiftUI

/// A single row in the list: a bolt glyph and the Pokémon's name inside a
/// rounded card. Matches the reference design (name only, no sprite).
struct PokemonRow: View {
    let pokemon: Pokemon

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "bolt.fill")
                .font(.headline)
                .foregroundStyle(.primary)
                .accessibilityHidden(true)

            Text(pokemon.name.capitalized)
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(pokemon.name.capitalized)
    }
}

/// A placeholder row shown while the first page is loading.
struct SkeletonRow: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.secondarySystemBackground))
            .frame(height: 58)
            .shimmering()
            .accessibilityHidden(true)
    }
}

#Preview("Row") {
    VStack(spacing: 12) {
        PokemonRow(pokemon: Pokemon(id: 1, name: "bulbasaur"))
        PokemonRow(pokemon: Pokemon(id: 25, name: "pikachu"))
        SkeletonRow()
    }
    .padding()
}
