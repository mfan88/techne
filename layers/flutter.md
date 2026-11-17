## Layers: Flutter

| Role | Paths | Pattern | Check |
| --- | --- | --- | --- |
| component | `lib/features/<f>/widgets/`, `lib/shared/widgets/` | `StatelessWidget` with a `const` constructor; data and callbacks as parameters | `dart format <files> && flutter analyze <files>` |
| logic | `lib/features/<f>/state/`, `lib/features/<f>/domain/` | The project's state pattern (Riverpod `Notifier` or Bloc); states as freezed unions | `dart format <files> && flutter analyze <files>` |
| wiring | `lib/app/router.dart`, `lib/features/<f>/<f>_screen.dart`, provider registration | Screen is a `ConsumerWidget`/`BlocBuilder` that maps state to widgets | `flutter analyze` |

**Contract format:** Dart signatures.
```dart
class EventListState { final List<Event> events; final bool loading; final Failure? error; }
EventList({required List<Event> events, required ValueChanged<Event> onTap, VoidCallback? onRetry})
GoRoute(path: '/events', name: 'events')
```

**Component rules:** theme tokens and l10n only; `Semantics` labels on every control; tap targets ≥ 48 dp; layout holds at text scale 2.0; keys on dynamic list items.
**Logic rules:** check `mounted`/`ref.mounted` after every `await`; dispose controllers, streams and timers; `DateTime` UTC in state, local only for display; never leak `DioException`/`PlatformException`.
**Wiring rules:** no logic in `build()`; route names from the contract; deep-link paths documented in `docs/app-map.md`.
**Integration check (tester):** `flutter analyze && flutter test test/features/<f>/`

### QA: Flutter
- **Levels and paths:** unit `test/<mirror of lib>/` · widget `test/features/<f>/widgets/` · rules `test/features/<f>/<f>_rules_test.dart` (one test per spec rule, named `'R<n>: <rule>'`; `PRODUCT DECISION` rows get `skip:` with the question) · golden `test/goldens/` (stable, design-critical widgets only, light and dark) · integration `integration_test/`.
- **Doubles:** mocktail; fake repositories for state tests; mocked HTTP client or fake dio adapter for repositories; fixtures in `test/fixtures/<f>_fixtures.dart`; service fakes in `lib/data/fakes/`.
- **Required case kinds:** repositories cover success, empty, 401, 403, 429 with `Retry-After`, 5xx, malformed JSON, pagination. Widgets cover every spec state plus `meetsGuideline(androidTapTargetGuideline)`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline` and a 2.0 `textScaler`.
- **Provider smoke tests:** `integration_test/providers/`, credentials from dart-defines only.
- **Commands:** narrow `flutter test <paths> --reporter expanded` · full `flutter test` · static `flutter analyze` · per-test coverage: none (optimizer works statically).
- **Flakiness:** `pumpAndSettle` with infinite animations, real `DateTime.now()` (inject a clock), unawaited futures.
