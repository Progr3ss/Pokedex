//
//  RootView.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import SwiftUI

/// App entry view. Delegates dependency wiring to the composition root.
struct RootView: View {
    var body: some View {
        PokemonListComposer.makeListView()
    }
}
