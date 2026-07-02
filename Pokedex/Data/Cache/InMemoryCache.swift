//
//  InMemoryCache.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Foundation

/// A small, reusable, thread-safe in-memory cache. Implemented as an `actor`
actor InMemoryCache<Key: Hashable & Sendable, Value: Sendable> {
    private var storage: [Key: Value] = [:]

    func read(_ key: Key) -> Value? {
        storage[key]
    }

    func write(_ value: Value, for key: Key) {
        storage[key] = value
    }

    func clear() {
        storage.removeAll()
    }
}
