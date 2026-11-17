## Layers: Swift (SwiftUI, iOS)

| Role | Paths | Pattern | Check |
| --- | --- | --- | --- |
| component | `<App>/Views/Components/`, `<App>/Features/<F>/Views/` | `struct` View with `let` inputs and closure callbacks; a `#Preview` per contract state | `swift-format lint <files>` |
| logic | `<App>/Features/<F>/Models/`, `<App>/Services/` | `@Observable @MainActor` models; services as actors or protocols | `swift-format lint <files>` |
| wiring | `<App>App.swift`, `NavigationStack` destinations, environment injection, App Intents / CarPlay scene registration | Container views that own the model and pass values into components | `xcodebuild -scheme <Scheme> -destination 'generic/platform=iOS Simulator' build -quiet` |

**Contract format:** Swift signatures.
```swift
struct PlaceRow: View { let place: Place; let eta: Duration?; let onSelect: () -> Void }
@Observable @MainActor final class TripModel { private(set) var state: LoadState<[Trip]>; func refresh() async }
protocol TravelTimeService: Sendable { func eta(from: Place, to: Place) async throws -> Duration }
```

**Component rules:** no `@State` for data, no environment model access, no `Task {}`; `.accessibilityLabel`/`.accessibilityHint` on controls; Dynamic Type up to accessibility sizes; SF Symbols and asset-catalog colors only.
**Logic rules:** UI state on `@MainActor`; cancel tasks on disappear; `Sendable` across actor boundaries; map errors to the contract's error enum; dates stored as `Date`, formatted only in views; EventKit and location access through the existing service protocols.
**Wiring rules:** dependency injection through `.environment` or initializers as the project does; no logic in `App` or scene delegates beyond registration.
**Integration check (tester):** the wiring build command, then `xcodebuild test -scheme <Scheme> -destination '<simulator>'`. Builders do not run `xcodebuild` in parallel: only wiring-builder runs it.

### QA: Swift
- **Levels and paths:** unit `<App>Tests/` with Swift Testing (`@Test`, `#expect`), or XCTest where the project uses it · UI `<App>UITests/` (critical flows only) · snapshot only if the project already has a snapshot library.
- **Doubles:** protocol-based fakes for services (`FakeTravelTimeService`), in-memory stores, injected `Clock` and `Calendar`/`TimeZone`; EventKit and location behind the existing protocols.
- **Async:** test `@MainActor` models with `await`; use `confirmation` (Swift Testing) or expectations for callbacks; never `sleep`.
- **Commands:** narrow `xcodebuild test -scheme <Scheme> -destination '<simulator>' -only-testing:<Target>/<Suite>` · full without `-only-testing` · static `swift-format lint -r <App>` · per-test coverage: none (optimizer works statically).
- **Flakiness:** real dates and time zones (fix both), animations in UI tests (disable via launch argument), shared singletons.
