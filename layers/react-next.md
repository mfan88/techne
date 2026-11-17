## Layers: React / Next.js (App Router, TypeScript)

| Role | Paths | Pattern | Check |
| --- | --- | --- | --- |
| component | `components/<feature>/`, `components/ui/` | Function component with an exported `Props` type; Server Component unless the contract says interactive | `npx eslint <files> && npx tsc --noEmit -p .` |
| logic | `hooks/`, `lib/<feature>/`, `app/**/actions.ts` | Custom hooks, server actions, the project's query library (TanStack Query / SWR) or RSC fetching | `npx eslint <files> && npx tsc --noEmit -p .` |
| wiring | `app/**/page.tsx`, `layout.tsx`, `route.ts`, `app/providers.tsx` | Pages and handlers that call logic and render components | `npx tsc --noEmit -p . && npx next lint` |

**Contract format:** TypeScript types and signatures.
```ts
export type EventListProps = { events: Event[]; onSelect: (id: string) => void; state: 'loading' | 'empty' | 'error' | 'ready' }
export function useEvents(range: DateRange): { data?: Event[]; status: 'pending' | 'error' | 'success'; error?: AppError; refetch(): void }
// app/events/page.tsx → /events, searchParams: { from?: string; to?: string }
```

**Component rules:** `'use client'` only when the contract marks the component interactive; native elements before ARIA; `next/link` for navigation and `next/image` for images; class names or tokens from the design system, no inline colors.
**Logic rules:** secrets and server-only modules never imported into client code (`import 'server-only'`); validate server action input (zod or the project's schema lib); every fetch handles abort and error; no `any`.
**Wiring rules:** pages only fetch, pass props and render; `route.ts` handlers parse input, call one logic function and map errors to status codes; set `metadata` where the contract says.
**Integration check (tester):** `npx tsc --noEmit -p . && npx next lint && npx vitest run <paths>` (or the project's runner); `npx next build` before release.

### QA: React / Next.js
- **Levels and paths:** unit `**/*.test.ts` beside the source · component `**/*.test.tsx` with Testing Library · integration route handlers and server actions with the runner's node environment · end-to-end `e2e/` with Playwright (critical flows only).
- **Doubles:** MSW for HTTP; module mocks only for server-only boundaries; fixtures in `test/fixtures/`.
- **Queries:** `getByRole` with an accessible name first, `getByLabelText` second, test IDs last. Assert what the user sees, never component internals or hook call counts.
- **Commands:** narrow `npx vitest run <paths>` (or `npx jest <paths>`) · full `npx vitest run` · static `npx tsc --noEmit -p . && npx next lint` · e2e `npx playwright test <spec>` · per-test coverage: none (optimizer works statically).
- **Flakiness:** fake timers for debounce and polling, `findBy*` instead of sleeps, no shared MSW handlers mutated across tests, Playwright auto-waiting instead of `waitForTimeout`.
