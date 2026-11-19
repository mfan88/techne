<!-- Installed as .claude/PM-routing.md. Blocks for sections that are not installed are removed at install. -->
Installed sections: {{SECTIONS}}. Skip any step whose agent is not in `.claude/agents/`; CLAUDE.md → Missing sections says what replaces it.

## Routing build work

### Pick the builder
<!-- if:build -->
| Slice | Agent(s) |
| --- | --- |
| Touches one layer, at most 2 files, no new state | `feature-builder` alone, or the single layer agent |
| UI plus state plus a route/registration | `component-builder` + `logic-builder` in parallel, then `wiring-builder` |
| Copy, strings, token values, asset swaps | `feature-builder` with `model: haiku` |
| Something is broken | the bug flow below |
| Anything touching a third-party API or auth | the integration flow below |
<!-- endif -->
<!-- if:api -->
New endpoint, auth, scopes or DTOs: `api-integrator` first; its interfaces go into the contract.
<!-- endif -->
<!-- if:!build -->
No build agents: you implement each subtask yourself against its contract. Write the contract anyway; it is what the testing and review agents check against.
<!-- endif -->

### Write the contract before any builder runs
Every layered work order starts with a **Contract** block in the stack's contract format (see the Layers file), and the same block goes to every builder on the slice:
```
Slice: <feature>/<slice-id>   Stack: <flutter | react-next | react-native | swift | pytorch-ml | docker>
Goal: <one sentence>
Contract:
  <types, signatures, shapes, routes, image spec>
Files (per agent): component: <paths> | logic: <paths> | wiring: <paths>
Read: <spec rows R3–R7 pasted or cited>, <tokens/config file>, example: <one existing file to copy>
States/variants: <list>
Done when: <checks pass + observable result>
```
Rules for the brief:
- Name exact files. Builders do not explore, so a missing file becomes `NEEDS SCOPE`.
- Paste the relevant spec rows instead of pointing at the whole spec.
- Always give one example file to copy. Haiku follows an example far better than a description.
- Settle every product question first. A `QUESTION:` from a builder means the brief had a gap: answer it and rerun on the **same** model.

### Pipeline for a task
Run the installed lines in this order; a missing line is skipped.
<!-- if:build -->
- **build:** component-builder ∥ logic-builder → wiring-builder (feature-builder for small slices)
<!-- endif -->
<!-- if:!build -->
- **build:** you, one subtask at a time, running the Layers check commands
<!-- endif -->
<!-- if:testing -->
- **testing:** test-designer → test-optimizer (plan) → test-writer → tester → qa-reviewer
<!-- endif -->
<!-- if:!testing -->
- **checks:** you run `AGENTS.md` → Commands (analyze, lint, tests) on the changed paths
<!-- endif -->
<!-- if:review -->
- **review:** code-reviewer per slice (in parallel with qa-reviewer when testing is installed); fixes loop back to the owner
<!-- endif -->
<!-- if:docs -->
- **docs:** docs-writer for user-visible or public-API changes
<!-- endif -->
<!-- if:review -->
- **gate:** final-reviewer once per task → push and `gh pr create` with its title and body
<!-- endif -->
<!-- if:!review -->
- **gate:** your self-check (CLAUDE.md → Gates) → push and `gh pr create`
<!-- endif -->

<!-- if:testing -->
- **Skip what a slice does not need.** Copy or token change: build → tester → gate. One-file slice: skip test-designer and test-optimizer, put 1–3 cases in the work order and send them straight to test-writer. Docs-only: docs → gate.
- **Test budget:** give test-designer a budget per slice (default 12). Raise it for auth, payments, data loss and algorithms; lower it for UI-only slices.
- **Suite mode:** run test-optimizer in suite mode on a feature's tests when its suite grows past about 40 tests or after several slices land, not on every task.
- **Plans** live in the QA plan directory (default `.qa/`, gitignored). Pass the plan path to test-writer and qa-reviewer.
<!-- endif -->
<!-- if:review -->
- **Feed reports forward:** code-reviewer gets the tester report (or your check output); final-reviewer gets every final report, every contract and the acceptance criteria, and is told which sections are installed. Pass only the final report of each agent, not earlier rounds.
- **After READY:** push and open the PR with the title and body exactly as given. If anything was committed after final-reviewer ran, run it again.
<!-- endif -->

<!-- if:build -->
### Model per run
Defaults are in the agent files (component and wiring on haiku, logic on sonnet). Override per call with the Agent tool's `model` parameter:
- Raise logic-builder to `opus` (or keep sonnet at high effort) for new algorithms, losses, concurrency or anything numerically delicate.
- Lower logic-builder to `haiku` only for state that mirrors an existing pattern line for line.

<!-- endif -->
### Escalation
- Check fails after the builder's own fix attempt → rerun that slice once on the next model up (haiku → sonnet → opus).
<!-- if:build -->
- `MISMATCH:` from wiring-builder → send the item back to the agent that owns the file, same model. A second mismatch on the same item means the contract is wrong: fix the contract, not the code.
- `CONTRACT CHANGE:` → decide, update the contract block, rerun every builder it affects.
- `LOGIC NEEDED:` → route that item to logic-builder.
<!-- endif -->
<!-- if:testing -->
- `BUG:` from test-writer or `FAILED x3` from tester → a fix work order to the builder that owns the file (bug flow).
- `PLAN GAP:` → test-designer, same model.
<!-- endif -->
<!-- if:review -->
- `NOT READY` from final-reviewer → route each item to its owner, then rerun the gates and final-reviewer.
<!-- endif -->
- The same slice escalated twice → stop and do it yourself, or ask the user.

<!-- if:design -->
## Design passes (Figma)
Each design agent edits only its own field in the Figma file:

| Order | Agent | Model | Figma field | Doc |
| --- | --- | --- | --- | --- |
| 0 | app-bridge (context) | sonnet | bridge notes | context.md |
| 1 | ui-researcher | haiku | `<feature>/research` board | research.md |
| 2 | canvas-designer | sonnet | frames, components, prototype, decision storyboards | flow.md |
| 3 | ui-layout-engineer | sonnet (high) | auto layout, spacing/radius variables, responsive variants | spec.md |
| 3b | type-designer | haiku | text styles, type variables, text-layer bindings | type.md |
| 4 | color-designer | haiku | color variables, modes, bindings | tokens.md |
| 5 | a11y-designer | sonnet | a11y annotations, focus states; can VETO | a11y.md |
| 6 | design-reviewer | sonnet (high) | review notes only; any HIGH blocks the build | review.md |
| 7 | app-bridge (feasibility, Code Connect) | sonnet | Code Connect, bridge notes | feasibility.md |

- One Figma writer at a time on the same frames. type-designer and color-designer may prepare their variables and styles in parallel with layout; they bind them to frames only after layout is done, one at a time.
- design-reviewer findings go to the owner named in each row; rerun design-reviewer on the changed frames only (re-review).
- `REQUEST <agent>: …` items in a report become the next work order for that agent. Do not let an agent edit outside its field to save a round trip.
- `DECISION NEEDED` from canvas-designer → ask the user with the prototype link before any later pass.

<!-- endif -->
## Bug flow
<!-- if:testing -->
1. test-designer writes the reproducing case(s) from the bug report (budget 1–3).
2. test-writer writes them; they must fail. If they pass, the bug is not reproduced: ask the user for steps.
3. Fix work order naming the failing test IDs, to the owner of the failing file (a builder, api-integrator for the data layer, or you without build). Use logic-builder on opus when the cause is unclear.
4. The rest of the gates.
<!-- endif -->
<!-- if:!testing -->
1. Reproduce from the user's steps and find the file at fault.
2. Fix work order to its owner (a builder, api-integrator, or you without build).
3. Rerun the steps and the checks, then the rest of the gates.
<!-- endif -->

## Integration flow
1. You write `docs/integrations/<provider>-plan.md` from `templates/integration-plan.md`: auth flow, scopes, endpoints and contracts, errors and retries, config and secrets per platform, verification checklist, slices.
2. The user approves it (`Status: APPROVED`). Open decisions block approval.
<!-- if:api -->
3. api-integrator implements one plan slice per work order; logic and UI slices consume its interfaces through the contract.
4. integration-verifier runs the plan's checklist. Console and portal items go to the user.
<!-- endif -->
<!-- if:!api -->
3. Plan slices go to logic-builder as contracts (or to you, without build).
4. You run the plan's verification checklist. Console and portal items go to the user.
<!-- endif -->
5. The gates as usual.

<!-- if:release -->
## Release
- Websites and web apps: no release-manager; deploys come from the host's Git integration.
- Mobile (App Store Connect API or Expo EAS), desktop (GitHub Actions to GitHub Releases), Docker (GHCR): install with `--release <targets>`, then one release-manager **setup** work order per project.
- Each release: a release-manager **release** work order with the bump → push the tag it prints only after the user approves (`APPROVED TO RELEASE`).
<!-- endif -->
