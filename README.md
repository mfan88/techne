# techne

*τέχνη: craft, the skill of making things well.*

techne is a drop-in team of [Claude Code](https://code.claude.com) subagents, skills and commands that turns your main Claude session into a project manager. It plans the work, writes exact contracts, and delegates each piece to a narrowly scoped agent on the cheapest model that can do it well. A QA team checks the work, and an Opus merge gate approves it before a PR is opened.

One command installs it into any project: web, mobile, desktop, ML or containers.

```bash
curl -fsSL https://raw.githubusercontent.com/mfan88/techne/main/install.sh | bash
```

The interactive installer asks what you are building, whether you design in Figma, whether you use Linear, whether agents or you make the commits, and whether to add release credentials now. Then it installs the right team.

---

## Why

Large single-agent sessions are slow and expensive: one top-tier model reads everything and does everything. techne splits the work the way a team would:

- **The main agent decides; subagents execute.** Contracts, plans and acceptance criteria are written once by the main agent. Builders implement against them without exploring the codebase.
- **The cheapest model that is reliable for each job.** Haiku builds UI components and wiring from an exact contract. Sonnet handles state, algorithms and judgement-heavy review. Opus is used only for the merge gate.
- **Small, isolated contexts.** Subagents skip `CLAUDE.md`, read only the files their work order names, and return reports under 10–15 lines.
- **Tests that earn their place.** A test designer plans the minimum set of cases. A test optimizer removes redundant ones before they are written, so you don't end up with 100 overlapping tests.
- **One task per session.** Every task starts in a fresh session, and at most two run in parallel.

## The roster

| Team | Agent | Model | What it does |
| --- | --- | --- | --- |
| **Design (Figma)** | app-bridge | sonnet | How the app really works: context, answers, feasibility; Code Connect |
| | ui-researcher | haiku | Researches UI patterns with Mobbin; builds a research board |
| | canvas-designer | sonnet | Frames, components, clickable prototype, decision storyboards |
| | ui-layout-engineer | sonnet | Auto layout, spacing variables; writes the spec and behavior rules |
| | type-designer | haiku | Text styles, type scale, platform text scaling |
| | color-designer | haiku | Color variables, light/dark modes, bindings; measured contrast |
| | a11y-designer | sonnet | Accessibility annotations and focus states; can veto the build |
| | design-reviewer | sonnet | Cross-discipline review of the finished design; any HIGH finding blocks the build |
| **Build** | component-builder | haiku | Pure UI components, functions, ML modules, Dockerfile stages |
| | logic-builder | sonnet | State, async, business logic, training loops, algorithms |
| | wiring-builder | haiku | Routes, dependency injection, registration: mapping only |
| | feature-builder | sonnet | Slices too small to split; on haiku for copy and token changes |
| **Integrations** | api-integrator | sonnet | Data layer and auth, strictly from an approved integration plan |
| | integration-verifier | haiku | Runs the plan's verification checklist with evidence |
| **QA** | test-designer | sonnet | Minimal test plan: partitions, boundaries, transitions, budget |
| | test-optimizer | sonnet | Removes duplicate, subsumed and over-leveled tests |
| | test-writer | haiku | Writes exactly the planned cases |
| | tester | haiku | Runs checks and suites; reports the commit tested |
| | qa-reviewer | sonnet | Would these tests actually catch a bug? |
| | code-reviewer | sonnet | Per-slice code review |
| | docs-writer | haiku | Changelog, doc comments, docs sections |
| **Gate and release** | final-reviewer | **opus** | Acceptance evidence, scope, fresh test results, merge-conflict check, PR text |
| | release-manager | sonnet | Release scripts, shortcuts and CI per target (not for websites) |

Each Figma design agent can only edit its own part of the file: research board, frames, layout, typography, color, accessibility notes, review notes or Code Connect. Anything outside its part goes back to the main agent as a `REQUEST`.

## How work flows

```
plan     main agent: phase task file or Linear issues → contract → work orders
design   app-bridge → ui-researcher → canvas-designer → ui-layout-engineer → type-designer → color-designer → a11y-designer → design-reviewer
build    component-builder ∥ logic-builder → wiring-builder → tester
QA       test-designer → test-optimizer → test-writer → tester → qa-reviewer ∥ code-reviewer → docs-writer
gate     final-reviewer → READY → main agent pushes and opens the PR
```

- **Bugs:** a failing reproduction test first, then a fix work order to the agent that owns the file.
- **Integrations:**
  1. The main agent writes an integration plan.
  2. You approve it.
  3. api-integrator implements it.
  4. integration-verifier checks it.
- **Releases:** release-manager sets up the automation once. After that it prepares each version, and nothing ships until you approve.

### Build modes

| | `--mode small` (Docker images, quick tools) | `--mode large` (apps, multi-phase products) |
| --- | --- | --- |
| Commits | Only you. The main agent suggests a commit message after each task | Subagents commit (never push) with `Co-Authored-By: Claude <agent-name>` |
| Concurrency | One task at a time | Up to 2 task sessions, only for independent tasks |
| Finish | Stops for your review | final-reviewer → push → PR |

### Tasks

- **Local tracker:** one file per phase, `tasks/<what-the-phase-changes>-tasks.md`. Phases are lettered (A, B, …), tasks are `A1, A2`, and subtasks (one agent each) are `A1.1, A1.2`.
- **Linear tracker:** the same structure lives only in Linear.
  - The main agent moves Backlog → Todo.
  - Subagents move issues to In Progress and then In Review.
  - The PR stays In Review until you merge it.

## Stacks

Builders, QA and reviewers work on any stack. Stack presets supply the file paths, contract formats, rules for each layer, test levels and check commands:

`flutter` · `react-next` · `react-native` · `swift` · `pytorch-ml` · `docker`

Combine them for mixed projects, for example `--layers pytorch-ml,docker`.

## Requirements

- [Claude Code](https://code.claude.com)
- `git`, `bash`, `curl`, `tar`, `perl` (all preinstalled on macOS and most Linux distributions)
- [GitHub CLI](https://cli.github.com) (`gh`), signed in: used for PRs and for storing release credentials as Actions secrets
- Optional MCP servers:
  - **Figma** (design agents), registered as `figma` or renamed with `--figma-server`
  - **Mobbin** (ui-researcher), registered as `mobbin`
  - **Linear** (task tracking), registered as `linear` or renamed with `--linear-server`
- The design agents also need the Figma plugin's skills (`figma:figma-use`, `figma:figma-generate-design`, `figma:figma-code-connect`).

## Install into a project

Run from the project root:

```bash
curl -fsSL https://raw.githubusercontent.com/mfan88/techne/main/install.sh | bash
```

The installer first asks how you want to choose your agents.

**Set workflow** recommends a team for what you are building. Every section question includes an opt-out:

1. **What are you building?** Web app, React Native/Expo, Flutter, iOS (Swift), desktop, ML/Python service, Docker image or quick tool, or a custom mix of stacks
2. **Design section:** the eight Figma agents, or opt out
3. **API section:** the plan-gated integration agents, or opt out
4. **Core sections:** Build, Testing, Review and Docs, all ticked by default; untick any to opt out
5. **Release section:** the target for your project type (which stores, Docker image, …), or opt out

**Manual** lets you tick the sections you want, then pick your stacks and, if you chose Release, your release targets.

Both paths then ask:
- **Commits:** agents commit and open PRs (team mode), or you review and commit each task (solo mode)
- **Tasks:** local task files, or Linear (and your team key)
- **Release credentials:** add them now or later
- **Existing CLAUDE.md:** replace it (backup kept) or keep it

The last screen shows the equivalent flags, so you can repeat the install without the menus.

### Agent sections

| Section | Agents | When it is left out |
| --- | --- | --- |
| `design` | app-bridge, ui-researcher, canvas-designer, ui-layout-engineer, type-designer, color-designer, a11y-designer, design-reviewer (and their skills) | The main agent describes UI in each contract instead |
| `api` | api-integrator, integration-verifier | The integration plan is still required; builders implement it and the main agent runs its checklist |
| `build` | component-, logic-, wiring- and feature-builder | The main agent writes the code itself, one contract-sized subtask at a time |
| `testing` | test-designer, test-optimizer, test-writer, tester, qa-reviewer | The main agent runs the project's analyze, lint and test commands; no new tests unless asked |
| `review` | code-reviewer, final-reviewer | The main agent checks acceptance, stray files and merge conflicts itself before the PR |
| `docs` | docs-writer | Whoever builds the slice adds the changelog line |
| `release` | release-manager (installed by `--release`) | No release automation |

The installer writes your sections into `CLAUDE.md`, `.claude/PM-routing.md`, `AGENTS.md` and `/task`. It removes instructions for missing sections and adds the fallback for each one, so the workflow skips those steps instead of waiting on an agent that isn't there.

### Flags (CI, scripts, or skipping the menus)

Any of these flags skips the menus. Without a terminal, the installer uses the flags or defaults.

```bash
curl -fsSL https://raw.githubusercontent.com/mfan88/techne/main/install.sh | bash -s -- [options]
# or from a clone
git clone https://github.com/mfan88/techne ~/techne
~/techne/install.sh --from ~/techne [options]
```

| Option | Meaning |
| --- | --- |
| `--sections LIST` | Comma-separated: `design`, `api`, `build`, `testing`, `review`, `docs` (default: all six). `core` = build,testing,review,docs and `integrations` = api still work. `--profile` is an alias |
| `--layers LIST` | Stack presets, written to `.claude/LAYERS.md` |
| `--release LIST` | `ios-asc`, `android-play`, `expo-eas`, `desktop-gha`, `docker-ghcr`. Adds release-manager and prompts for credentials. Omit for websites |
| `--mode small\|large` | Commit and concurrency model (default `large`) |
| `--tracker local\|linear` | Where tasks live (default `local`) |
| `--linear-team KEY` | Linear team key |
| `--base BRANCH` | Base branch (default `main`) |
| `--figma-server`, `--linear-server` | Rename MCP tool prefixes to match how your servers are registered |
| `--ref TAG` | Install a pinned version of the roster |
| `--keep-claude-md` | Do not replace `./CLAUDE.md` |
| `--no-prompt` | Skip credential prompts (CI, cloud sessions) |
| `--global` | Install agents and skills into `~/.claude` (no CLAUDE.md, commands or prompts) |
| `--yes` | Skip the menus and use defaults for anything not given |
| `--dry-run` | Show what would be installed |

### Examples

```bash
# Next.js web app (no release automation)
… --sections core,design,api --layers react-next
# Expo app, tasks in Linear
… --sections core,design,api --layers react-native --release expo-eas --tracker linear --linear-team ENG
# Flutter app shipping to both stores
… --sections core,design,api --layers flutter --release ios-asc,android-play
# Native iOS app
… --sections core,design,api --layers swift --release ios-asc
# Desktop app (Qt, Electron, Tauri)
… --sections core,api --release desktop-gha
# ML inference API in a container
… --sections core,api --layers pytorch-ml,docker --release docker-ghcr
# Small Docker tool you commit yourself
… --sections core --layers docker --release docker-ghcr --mode small
# Builders and review only; you run the tests yourself
… --sections build,review --layers react-next
```

### What gets installed

```
CLAUDE.md                       main-agent spec (your old one is kept as CLAUDE.md.bak-<timestamp>)
AGENTS.md                       created from a template if missing: project facts the agents read
.claude/agents/                 the subagents in your sections
.claude/skills/                 bundled skills + /task, /next, /roster
.claude/LAYERS.md               stack presets
.claude/PM-routing.md           routing, contracts, pipelines, escalation (read on demand)
.claude/templates/              integration plan, AGENTS.md sections
.claude/release/, release.md    release recipes and credential names (no values)
.claude/.techne.lock            what was installed, from which commit
```

### After installing

1. Fill in `AGENTS.md`: commands, conventions, the Figma file key, integration docs.
2. Connect the MCP servers you use (`claude mcp add …`).
3. Start Claude Code and plan the first phase, or run `/next`.

## Commands

| Command | What it does |
| --- | --- |
| `/task A3` | Checks dependencies, status, the session limit and file overlap, then starts the task, or hands it to a fresh session |
| `/next` | Starts the first ready task in the queue |
| `/roster` | Lists the installed agents with their models |

## Release automation

| Project | Target | Credentials prompted at install |
| --- | --- | --- |
| Website / web app | none | none |
| iOS (Swift, Flutter) | `ios-asc` | App Store Connect API key (ID, issuer, `.p8`), team ID, bundle ID |
| Android | `android-play` | Play service-account JSON, upload keystore and passwords |
| React Native / Expo | `expo-eas` | `EXPO_TOKEN` (store keys are kept on EAS) |
| Desktop | `desktop-gha` | Optional: macOS Developer ID `.p12` + App Store Connect key for notarization; optional Windows `.pfx` |
| Docker | `docker-ghcr` | none (uses `GITHUB_TOKEN`) |

- Credentials are read from your terminal, including under `curl | bash`. They are stored only as GitHub Actions secrets through `gh`, and never written to the repo. Only their names are recorded in `.claude/release.md`.
- Your App Store Connect key is also copied to `~/.appstoreconnect/private_keys/` for local builds.
- Skip any prompt with Enter. The installer prints the `gh secret set` commands for anything still missing.

## Updating and pinning

Re-run the installer to update. It overwrites techne's files and leaves your `AGENTS.md`, task files and app code alone. Tag releases of this repo and install with `--ref vX.Y.Z` to pin a project.

## Customizing

- **Add an agent:** drop a Markdown file with Claude Code subagent frontmatter in `agents/` and add its name to a section file in `profiles/`. Keep it narrow, give it an explicit tool allowlist, a stop condition, and a short report format.
- **Add a stack:** copy a file in `layers/` and fill in the component, logic and wiring rows, the contract format, the rules and the QA section.
- **Add a release target:** add `release/recipes/<target>.md`, plus its prompts in `release/release-setup.sh`.
- **Change models:** edit the agent's `model` and `effort`, or have the main agent override them per call. Model choices are explained in [ROSTER.md](ROSTER.md).

## Repository layout

```
agents/            subagent definitions
skills/            skills the design agents use (accessibility, color, layout, typography, writing, UI, interface review)
claude/            CLAUDE.md template and the /task, /next, /roster commands
layers/            stack presets
profiles/          one file per agent section
templates/         PM routing, integration plan, AGENTS.md sections
release/           release recipes and the credential setup script
install.sh         the installer
tui/               the interactive installer menus
ROSTER.md          model policy and per-agent rationale
```

## Security

- Agents never push to the base branch, force-push, upload releases or move tracker issues to Done.
- Release and integration work stops for your explicit approval.
- `install.sh` is piped to bash: read it first, and pin a tagged version (`--ref`) for anything important.

## License

techne is released under the [MIT License](LICENSE). Bundled skills keep their own licenses, listed below.

## Credits and licenses

techne bundles skills from two open-source projects. Thank you to their authors.

| Skills | Source | Author | License |
| --- | --- | --- | --- |
| `better-accessibility`, `better-colors`, `better-interface`, `better-layout`, `better-typography`, `better-ui`, `better-writing` | [jakubkrehel/skills](https://github.com/jakubkrehel/skills) | Jakub Krehel | MIT (`LICENSE` in each skill folder) |
| `color-expert` | [meodai/skill.color-expert](https://github.com/meodai/skill.color-expert) | [@meodai](https://github.com/meodai) | CC BY 4.0 for the original material; third-party reference content stays under its original licenses (see `LICENSE` and `THIRD_PARTY_NOTICES.md`) |

Changes in techne: the `better-*` skills are unmodified. In `color-expert`, the `description` in `SKILL.md` was rewritten so it does not compete with `better-colors` for UI color work, and the installer leaves out its maintainer-only files (`README.md`, `CLAUDE.md`, `ROADMAP.md`, `MAINTENANCE.md`, `SECURITY.md`, `evals/`, `scripts/`). Its `LICENSE` and `THIRD_PARTY_NOTICES.md` always ship with it.

To get updates or the full collections, install the skills from their original repositories.
