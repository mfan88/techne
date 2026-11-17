# techne roster: models and rationale

How each agent's model and effort were chosen, and how the pipelines fit together. Installation and options are in [README.md](README.md).

## Model policy

- **opus:** only the merge gate.
- **sonnet:** work where judgement is needed and a brief cannot fully specify it.
- **haiku:** work an exact contract, plan, checklist or example fully specifies.

The main agent overrides any agent per call with the `model` parameter (escalation rules are in PM-routing).

| Agent | Model | Effort | Role |
| --- | --- | --- | --- |
| **Design (Figma, one field each)** | | | |
| app-bridge | sonnet | medium | Code truth: context, answers, feasibility; Code Connect and bridge notes |
| ui-researcher | haiku | medium | Mobbin research and the `<feature>/research` board |
| canvas-designer | sonnet | medium | Frames, components, prototype, decision storyboards |
| ui-layout-engineer | sonnet | high | Auto layout and spacing variables; spec.md and behavior rules |
| type-designer | haiku | medium | Text styles and type variables; measured rules from better-typography |
| color-designer | haiku | medium | Color variables, modes and bindings; measured contrast |
| a11y-designer | sonnet | medium | Accessibility annotations and focus states; can veto |
| design-reviewer | sonnet | high | better-interface review across all six design domains; judgement-heavy, so not haiku |
| **Build** | | | |
| component-builder | haiku | medium | Pure leaf units from a contract |
| logic-builder | sonnet | medium | State, async, algorithms (opus override for delicate work) |
| wiring-builder | haiku | low | Routes, DI, registration; mapping only |
| feature-builder | sonnet | medium | Slices too small to split; haiku for copy and token changes |
| **Integrations (plan-gated)** | | | |
| api-integrator | sonnet | high | Data layer and auth from an APPROVED plan |
| integration-verifier | haiku | medium | Runs the plan's checklist with evidence |
| **QA** | | | |
| test-designer | sonnet | medium | Minimal test plan within a budget |
| test-optimizer | sonnet | medium | Removes redundant cases (plan) and tests (suite) |
| test-writer | haiku | medium | Writes exactly the planned cases |
| tester | haiku | low | Runs checks; reports with the SHA |
| qa-reviewer | sonnet | medium | Do the tests catch bugs |
| code-reviewer | sonnet | medium | Per-slice code review |
| docs-writer | haiku | low | Changelog, doc comments, docs sections |
| **Gate and release** | | | |
| final-reviewer | **opus** | high | Acceptance evidence, scope, current tests, merge-conflict check, PR text |
| release-manager | sonnet | medium | Release scripts, shortcuts and workflows per target (not for websites) |


## Pipelines (details in templates/PM-routing.md)

- **Design:**
  - app-bridge context → ui-researcher → canvas-designer → ui-layout-engineer → type-designer → color-designer → a11y-designer → design-reviewer → app-bridge feasibility and Code Connect.
  - Only one agent writes to the same Figma frames at a time. Anything outside an agent's own area goes into its report as a `REQUEST`.
- **Build:** component-builder ∥ logic-builder → wiring-builder → tester.
- **QA:** test-designer → test-optimizer → test-writer → tester → qa-reviewer ∥ code-reviewer → docs-writer → final-reviewer → push and open the PR.
- **Bug:** a failing reproduction test first (test-designer → test-writer), then a fix work order to the builder that owns the file.
- **Integration:**
  1. The main agent writes `docs/integrations/<provider>-plan.md`, and the user approves it.
  2. api-integrator implements it.
  3. integration-verifier checks it.
- **Release:** release-manager setup once per project; release mode for each version; the user approves before the tag is pushed.

## Release targets

| Project | Targets | Credentials prompted |
| --- | --- | --- |
| Website / web app | none | — |
| iOS (Swift, Flutter) | `ios-asc` | ASC key ID, issuer ID, .p8, team ID, bundle ID |
| Android (Flutter, native) | `android-play` | Play service-account JSON, upload keystore and passwords, package |
| React Native / Expo | `expo-eas` | `EXPO_TOKEN` (store keys on EAS with `eas credentials`) |
| Desktop (Qt, Electron, Tauri) | `desktop-gha` | Optional macOS p12 + ASC key for notarization; optional Windows pfx |
| Docker | `docker-ghcr` | none (`GITHUB_TOKEN`) |

## MCP tool names
- Figma tools are `mcp__figma__*` and Mobbin tools are `mcp__mobbin__*`.
- Register the servers under those names, or pass `--figma-server <name>` to the installer.
- Every design agent has an explicit Figma tool allowlist. None can create files or send code to Figma. Only app-bridge has the Code Connect write tools.

## Skills
- Preloaded with `skills:` (preloaded skills cannot have `disable-model-invocation: true`):
  - `figma:figma-use`: every design agent.
  - `figma:figma-generate-design`: canvas-designer.
  - better-layout and better-ui: ui-layout-engineer.
  - better-colors: color-designer, which loads color-expert on demand.
  - better-typography: type-designer.
  - better-accessibility: a11y-designer.
  - better-interface: design-reviewer, which loads the six domain skills (accessibility, layout, writing, typography, colors, UI) on demand. better-writing is installed for this review only.
- color-expert is CC BY 4.0. Keep its LICENSE and THIRD_PARTY_NOTICES.
