# Pokédex

A small SwiftUI app that lists Pokémon from the [PokéAPI](https://pokeapi.co). It scrolls infinitely, caches pages it has already loaded, shows skeleton placeholders while the first page comes in, and recovers from network errors with a retry. Swift 6 with strict concurrency turned on, and no third-party dependencies.

## Build & Run

You'll need Xcode 16+ (for the Swift 6 toolchain) and an iOS 17 simulator or device.

1. Open `Pokedex.xcodeproj`.
2. Pick the Pokedex scheme and any iOS 17+ simulator.
3. Cmd-R to run, Cmd-U for the tests.

There's no API key or setup step. Code signing is turned off in the project settings, so it builds on the simulator without a development team.

The project file is generated from `project.yml` with [XcodeGen](https://github.com/yonyz/XcodeGen), so if you edit the file layout you can regenerate with `xcodegen generate`. That's only needed if you're changing the project structure though. The committed `.xcodeproj` builds fine as-is.

## Architecture

I kept the layers separated and pointed the dependencies in one direction: presentation depends on data, data depends on networking, and everything eventually bottoms out at plain domain value types. Each layer talks to the one below it through a protocol rather than a concrete type, which is what makes the whole thing testable.

Here's roughly where things live:

| Folder | What's in it |
|--------|--------------|
| `App/` | The entry point, `RootView`, and `PokemonListComposer` where all the concrete types get wired together |
| `Domain/` | `Pokemon` and `PokemonPage`, pure value types with no framework knowledge |
| `Networking/` | The `HTTPClient` protocol, its `URLSession` implementation, `NetworkError`, and the API config |
| `Data/` | The `PokemonRepository` protocol and its default implementation, the wire DTOs, and the cache |
| `Presentation/` | `PokemonListViewModel` and the SwiftUI views |
| `PokedexTests/` | Unit tests, plus reusable fakes and stubs under `Helpers/` |

A page load walks down through those layers and back up. A row appears, `InfiniteScrollView` reports it, and the view model decides whether it's close enough to the end to fetch the next page. If it is, it asks the repository, which checks its cache first and only hits the network on a miss. The response gets decoded into domain models, cached, and handed back. The view model appends the new items and updates its state, and SwiftUI redraws from there.

## Design decisions worth calling out

The dependency inversion is the backbone of everything else. Because the view model only knows about `PokemonRepository` and the repository only knows about `HTTPClient` and `PokemonPageCaching`, I can test each piece in isolation with a fake, and the one place that knows about the real `URLSession` and the concrete cache is `PokemonListComposer`. Swap the composition root and you can reassemble the app however you like.

The view model is a small state machine rather than a pile of `isLoading`/`hasError` booleans. The `State` enum separates a first-page load (which shows the full-screen skeleton) from loading another page (which shows a footer spinner), so the view can react to exactly the right situation. All of the pagination logic lives in the view model and is tested without a network.

The views try to stay dumb. `PokemonListView` just maps state onto sub-views, and `InfiniteScrollView` is fully generic. It works with any `Identifiable` item and a row builder you pass in, and it has no idea Pokémon exist. There's a `#Preview` that drives it with a list of fruit to prove that.

I kept the wire format out of the rest of the app. The DTOs decode the JSON and map into the domain `Pokemon`, including pulling the numeric id out of the detail URL, and a bad payload throws a typed `PokemonMappingError`. Nothing above the data layer ever sees the API's shape.

Concurrency was a first-class constraint. The project builds clean under Swift 6 with `SWIFT_STRICT_CONCURRENCY` set to `complete`. The view model is `@MainActor @Observable`, and the cache and test doubles are actors so shared state stays serialized without any manual locking. No Combine anywhere; it's all async/await, as the brief asked.

Caching is keyed by the page URL and checked before the network, so a page never gets fetched twice (including re-requests of the first page). The cache itself is a tiny generic actor.

Paging is defensive about failures. A single in-flight guard stops overlapping requests, and when a page fails it shows an inline retry in the footer while keeping whatever's already loaded on screen. It deliberately stops auto-paging after a failure so it isn't hammering an endpoint that's already returning errors. You have to tap retry.

Accessibility got some attention too: rows and headers are grouped with sensible VoiceOver labels, decorative glyphs are hidden, the title carries the header trait, and the shimmer effect falls back to a static state when Reduce Motion is on.

Tests use Swift Testing rather than XCTest. The fakes (`FakePokemonRepository`, `HTTPClientSpy`) make the async paths deterministic, and `URLProtocolStub` lets the real `URLSessionHTTPClient` run end to end without touching the network.

## Tradeoffs

The cache is memory-only, so it's gone on relaunch and there's no offline mode. That was a deliberate simplification for a browsable list, and since it's behind the `PokemonPageCaching` protocol a disk-backed version could drop in later without the repository noticing.

It's a list and nothing more: no detail screen, no sprites. Rows show the name with a decorative bolt icon to match the reference design. Skipping images kept the networking and caching story focused.

The page size is 10, which is small on purpose. It makes the pagination and the load-more threshold easy to watch and test. In production you'd bump it to cut down on round trips.

The cache never evicts. For the finite list of ~1300 Pokémon that's fine, but anything unbounded would need a size cap or TTL.

There's no `NavigationStack` and the app is a single portrait screen, because that's all the task needs. And the error strings are built in the view model, which is easy to test but isn't localized yet (see below).

## If I had more time

The big one is bringing in the Pokémon artwork. Right now the rows are name-only, so I'd fetch each Pokémon's sprite and show it in the list, with proper image caching (either `AsyncImage` plus a cache or my own loader) so scrolling stays smooth. That pairs naturally with adding navigation: make each row tappable and push a detail screen that shows the larger artwork along with the types, stats, and other info from the detail endpoint. The `InfiniteScrollView` is already generic and the domain model is already decoupled from the wire format, so both of these slot in without disturbing the existing layers.

I'd also fix the count label in `LoadedCountHeader`. It uses a hardcoded 34pt font that ignores Dynamic Type, so it won't grow for someone using larger text. That's the one real accessibility gap and it's a quick change to a scaling text style.

After that, roughly in order: persist the cache to disk and add a TTL so there's some offline support; move the user-facing strings into a String Catalog and localize them; write the XCUIAutomation flow the brief mentions (load, scroll, paginate, hit an error, retry) plus a few snapshot tests for the skeleton/error/loaded states; add search over the list; and add pull-to-refresh. Somewhere in there I'd also want some lightweight logging around load times and cache hit rate to actually tune the page size and prefetch threshold instead of guessing.
