//
//  InMemoryCacheTests.swift
//  Pokedex
//
//  Created by Martin Chibwe on 7/1/26.
//

import Testing
@testable import Pokedex

@Suite("InMemoryCache")
struct InMemoryCacheTests {

    @Test("returns nil for a key that was never written")
    func returnsNilForMissingKey() async {
        let cache = InMemoryCache<String, Int>()
        #expect(await cache.read("missing") == nil)
    }

    @Test("stores and retrieves a value by key")
    func storesAndRetrieves() async {
        let cache = InMemoryCache<String, Int>()
        await cache.write(42, for: "answer")
        #expect(await cache.read("answer") == 42)
    }

    @Test("writing the same key overwrites the previous value")
    func overwritesExistingValue() async {
        let cache = InMemoryCache<String, Int>()
        await cache.write(1, for: "k")
        await cache.write(2, for: "k")
        #expect(await cache.read("k") == 2)
    }

    @Test("clear removes all stored values")
    func clearRemovesEverything() async {
        let cache = InMemoryCache<String, Int>()
        await cache.write(1, for: "a")
        await cache.write(2, for: "b")
        await cache.clear()
        #expect(await cache.read("a") == nil)
        #expect(await cache.read("b") == nil)
    }
}
