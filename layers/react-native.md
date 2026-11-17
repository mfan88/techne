## Layers: React Native (Expo, TypeScript)

| Role | Paths | Pattern | Check |
| --- | --- | --- | --- |
| component | `src/components/<feature>/` (or `components/`) | Function component with a `Props` type, styles from theme tokens | `npx eslint <files> && npx tsc --noEmit` |
| logic | `src/hooks/`, `src/state/` (zustand/Redux/Query), `src/features/<f>/` | Hooks and stores in the project's pattern | `npx eslint <files> && npx tsc --noEmit` |
| wiring | `app/` (expo-router routes, `_layout.tsx`), providers | Route files that call hooks and render components | `npx tsc --noEmit && npx expo lint` |

**Contract format:** TypeScript types, plus the route path.
```ts
export type EventRowProps = { event: Event; onPress: (id: string) => void; compact?: boolean }
export function useEvents(): { events: Event[]; status: 'loading' | 'error' | 'ready'; retry(): void }
// app/(tabs)/events.tsx → /events
```

**Component rules:** `accessibilityRole` and `accessibilityLabel` on every pressable; hit area ≥ 44 pt (`hitSlop` if smaller); respect font scaling (no fixed heights on text); `Platform.select` only where the contract notes a platform difference; no web-only APIs.
**Logic rules:** clean up subscriptions and timers in effect cleanups; handle app background/foreground where the contract says; persist only through the project's storage wrapper; tokens only in SecureStore.
**Wiring rules:** route files stay thin; screen options (titles, headers) from the contract; deep links registered in `app.json` only when listed.
**Integration check (tester):** `npx tsc --noEmit && npx expo lint && npx jest <paths>`; `npx expo-doctor` before release.

### QA: React Native
- **Levels and paths:** unit `**/*.test.ts` · component `**/*.test.tsx` with React Native Testing Library · end-to-end Maestro flows in `.maestro/` (critical flows only).
- **Doubles:** MSW or the query client's test wrapper for data; `jest-expo` preset mocks for native modules; fixtures in `test/fixtures/`.
- **Queries:** `getByRole` / `getByLabelText` first; assert `accessibilityState` for toggles and disabled controls.
- **Commands:** narrow `npx jest <paths>` · full `npx jest` · static `npx tsc --noEmit && npx expo lint` · e2e `maestro test .maestro/<flow>.yaml` · per-test coverage: none (optimizer works statically).
- **Flakiness:** fake timers for animations (`jest.useFakeTimers` + `act`), no real `Date.now()`, reset stores between tests.
