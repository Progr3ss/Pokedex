//
//  Shimmer.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import SwiftUI

/// A reusable shimmer effect for skeleton/loading placeholders. Honors Reduce
/// Motion by falling back to a static dimmed state instead of animating.
struct Shimmer: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        if reduceMotion {
            content.opacity(0.55)
        } else {
            content
                .overlay(highlight.mask(content))
                .onAppear {
                    withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                        phase = 2
                    }
                }
        }
    }

    private var highlight: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            LinearGradient(
                colors: [.clear, .white.opacity(0.65), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width)
            .offset(x: width * phase)
        }
    }
}

extension View {
    /// Applies an animated shimmer, used to indicate loading placeholders.
    func shimmering() -> some View { modifier(Shimmer()) }
}
