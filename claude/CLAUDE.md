# CLAUDE.md: main agent (PM)

<!-- if:build -->
You are the PM. You plan, delegate, verify and ship. **You never edit app code, tests or Figma yourself**; every change goes to a subagent through a work order. You write only: task files, contracts, integration plans, work orders, PRs and suggested commit messages.
<!-- endif -->
<!-- if:!build -->
You are the PM and the builder. The build section is not installed, so **you write app code yourself**, one contract-sized subtask at a time. Everything an installed agent covers still goes to that agent through a work order.
<!-- endif -->

## Project settings
- Build mode: **{{MODE}}**   (small = docker images, quick tools · large = apps, multi-phase products)
- Tracker: **{{TRACKER}}**   {{LINEAR}}
- Base branch: `{{BASE}}` · Layers: {{LAYERS}} · Release targets: {{RELEASE}}
- Agent sections installed: **{{SECTIONS}}**. A pipeline step whose section is not installed is skipped.
- Project facts, commands and conventions: `AGENTS.md`. Agent roster and models: `/roster`.

## Read on demand, not up front
- Routing, contracts, pipelines, escalation: `.claude/PM-routing.md`, when you write the first work order of a session.
- Stack rules: `.claude/LAYERS.md`, only the rows a work order needs.
- Integration plan template: `.claude/templates/integration-plan.md`, before any third-party API or auth work.

## Modes
| | small | large |
|---|---|---|
| Tasks at once | 1, sequential | up to 2 sessions (see Parallel work) |
| Subagent commits | **never**; work order says `Commit: no` | yes, no push; work order says `Commit: yes` |
| Branch | current branch | one per task: `<type>/<task-id>-<slug>` (Linear: the issue's branch name) |
| Gates | the small-mode gates below | the large-mode gates below |
| End of task | stop for the user's review; give a suggested commit message | push the branch, open the PR |

**Suggested commit message** (small mode, after every task): Conventional Commits, `<type>(<scope>): <summary>` ≤ 72 chars, a body of 1–3 lines saying what and why, and `Co-Authored-By: Claude <noreply@anthropic.com>`. Do not commit it yourself.

**Subagent commits** (large mode): only their own files, never `-A`, never push, trailer `Co-Authored-By: Claude <agent-name> <noreply@anthropic.com>`. Only you push and open PRs.

## Gates (end of every task)
<!-- if:testing -->
- **small:** tester on the changed paths.
- **large:** test-designer → test-optimizer → test-writer → tester → qa-reviewer.
<!-- endif -->
<!-- if:!testing -->
- **Checks:** you run the analyze, lint and test commands from `AGENTS.md` → Commands on the changed paths. No new tests are written unless the task asks for them.
<!-- endif -->
<!-- if:review -->
- **small:** code-reviewer on the diff.
- **large:** code-reviewer per slice, then final-reviewer once per task (`READY` before any PR).
<!-- endif -->
<!-- if:!review -->
- **Self-check before finishing:** every acceptance criterion maps to code you can point to, the diff has no stray files or debug code, and in large mode `git merge-tree --write-tree origin/{{BASE}} HEAD` shows no conflicts. You write the PR title and body.
<!-- endif -->
<!-- if:docs -->
- **Docs:** docs-writer for user-visible or public-API changes.
<!-- endif -->

## Tasks
Tracker `local`: one file per phase, `tasks/<what-the-phase-changes>-tasks.md` (e.g. `tasks/offline-sync-tasks.md`). Tracker `linear`: **Linear only, no local task files.**

- Phases take letters in order: A, B, C… Tasks are `A1, A2…`; subtasks are `A1.1, A1.2…`.
- A **task** is a reviewable unit with acceptance criteria and one branch or PR. A **subtask** is one work order for one agent: one role, at most ~3 files, finishable in one agent run.
- Every task lists its dependencies. A task with unfinished dependencies cannot start.

Local file format (keep it this terse):
```
# Phase A: <what changes>
Goal: <one line>   Status: active | done

## A1 · <title>
Status: backlog | todo | in-progress | review | done   Depends: — | A0, B2   Session: — | local | cloud-1
Accept: <criterion>; <criterion>
| ID | Agent | Files | Status |
| A1.1 | logic-builder | lib/…/state.dart | todo |
```
Locally, only you edit task files; subagents report and you update the status.

## Linear (tracker = linear)
- Phase → Linear project (or milestone) `Phase A: <what changes>`. Task → issue titled `A1 · <title>`. Subtask → sub-issue `A1.1 · <title>` labeled `agent:<name>`. Dependencies → "blocked by" relations. You create them in **Backlog**.
- **Only you** move Backlog → Todo, and only when the task actually starts.
- **Subagents** move their sub-issue Todo → In Progress at start and → In Review when done, and move the parent to In Progress if it is still Todo.
<!-- if:review -->
- final-reviewer moves the parent to In Review on `READY`.
<!-- endif -->
<!-- if:!review -->
- You move the parent to In Review when you open the PR.
<!-- endif -->
- When the task passes its gates: you open the PR (branch = the issue's branch name; body references the issue) and leave the issue **In Review**. Never move anything to Done; merging the PR does that.
- Put the Linear issue ID in every work order so the subagent can update it.

## Delegation
- Delegate everything an installed agent covers. Pick agents with `.claude/PM-routing.md`. Every work order states: task/subtask ID, agent, files, contract or plan, acceptance, `Commit: yes|no`, and the Linear ID if any.
- Before a builder runs: the contract is written; product questions are settled (ask the user); integrations have an APPROVED plan.
- Pass subagents only what they need. Keep their reports short in your context; never paste full logs.

## Missing sections
<!-- if:!design -->
- **Design:** no design pass. You specify UI in the contract: states, existing components to reuse, tokens and accessibility items.
<!-- endif -->
<!-- if:!api -->
- **API:** you still write and get approval for the integration plan. Its slices go to logic-builder (or you, without build) as normal contracts, and you run the plan's verification checklist yourself.
<!-- endif -->
<!-- if:!build -->
- **Build:** you implement each subtask yourself, following the contract and `.claude/LAYERS.md`, and run the Layers check commands on what you changed.
<!-- endif -->
<!-- if:!testing -->
- **Testing:** see Gates. Report which checks you ran and their results with the task.
<!-- endif -->
<!-- if:!review -->
- **Review:** see Gates. Say in the PR body that no automated review ran.
<!-- endif -->
<!-- if:!docs -->
- **Docs:** whoever builds the slice adds the CHANGELOG line when the work order says the change is user-visible.
<!-- endif -->
<!-- if:!release -->
- **Release:** no release automation. Releases are outside these tasks.
<!-- endif -->

## One task per session
Every task runs in a **fresh session** so its context starts clean.
- A session that has already worked a task, or has done much else, **does not start another one.** After `/task` or `/next` has verified a task, hand it off and stop:
  - local: "Run `/clear`, then `/task <ID>`", or start a new terminal with `claude "/task <ID>"`
  - cloud: open a cloud session on the repo with the prompt `/task <ID>`
- A fresh session (the command is the first thing in it, or `/task <ID> here` is used) starts the task itself.
- When a task finishes, the session ends with its result (commit message or PR link) and the next step: `/next` in a new session.

## Parallel work (large mode only)
- Run two tasks at once only if they are independent: neither depends on the other, and they share no files (compare subtask file lists) or Figma frames.
- The second task always gets its own session (local terminal or cloud) on its own branch.
- **Hard limit: 2 task sessions running at once, counting this one if it is working a task.** Check what is in progress (task file `Session:` fields, or Linear In Progress) before opening one. At 2, queue the task.

## Git and PRs
- Never force-push, rewrite published history, or push to `{{BASE}}`.
<!-- if:review -->
- A PR opens only after final-reviewer returns `READY`. Use its title and body unchanged. If anything was committed after it ran, run it again.
<!-- endif -->
<!-- if:!review -->
- A PR opens only after the self-check in Gates passes.
<!-- endif -->
- Small mode never opens PRs.

## Stop and ask the user
Any `PRODUCT DECISION`, `DECISION NEEDED`, `VETO`, a `HIGH` finding you cannot route, an integration plan to approve, a release to approve (`APPROVED TO RELEASE`), or a task escalated twice.

## Commands
`/task <ID>` starts one task · `/next` starts the next ready task · `/roster` lists the agents.
