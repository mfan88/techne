---
name: task
description: Start one task by ID after verifying its dependencies.
argument-hint: "[task ID, e.g. A3] [here]"
disable-model-invocation: true
---
Start the task named by the first word of **$ARGUMENTS** (the ID). Follow CLAUDE.md for mode, tracker and limits.

## 1. Find it
- Tracker `local`: `grep -n "^## <ID> ·" tasks/*-tasks.md`, then read only that task's block.
- Tracker `linear`: find the issue titled `<ID> · …` and read its state, its blocked-by relations and its sub-issues.
- Not found, or no ID given: stop and say so.

## 2. Verify it can start (all must pass)
1. **Dependencies:** every task in `Depends:` (or every blocked-by issue) is `done`, or `review` with its PR merged into the base branch. Check the actual state of each one; a `review` task whose PR is still open does not count.
2. **Status** is `backlog` or `todo`. If it is `in-progress` or `review`, report who has it and stop.
3. **Session limit:** count tasks in progress (task files' `Session:` fields, or Linear In Progress parents). Small mode: 0 others allowed. Large mode: fewer than 2 in total, counting this one.
4. **Independence** (large mode, when another task is running): no shared files or Figma frames between the two tasks' subtasks. Otherwise queue it.
5. **Ready inputs:** acceptance criteria present; product questions settled; an APPROVED integration plan if it touches an integration; design passes done if it builds UI from Figma.

If any check fails: report `BLOCKED: <ID>` with each failing check and what unblocks it (e.g. "A2 in review, PR #14 open"), suggest `/next`, and stop. Change nothing.

## 3. Fresh session or hand off
Start here only if this session is fresh: this command is the first thing in it, or `$ARGUMENTS` contains `here`. Otherwise change nothing and reply with the handoff, then stop:
- local: run `/clear`, then `/task <ID>`; or open a new terminal with `claude "/task <ID>"`
- cloud (large mode, parallel work): open a cloud session on the repo with the prompt `/task <ID>`

## 4. Start it
1. Mark it started: locally, `Status: in-progress` and `Session: local`. On Linear: Backlog → Todo (only you do this); the subagents move it to In Progress.
2. Large mode: create the task branch from an up-to-date `{{BASE}}` (Linear: the issue's branch name). Small mode: stay on the current branch.
3. Break the task into subtasks if it has none: one agent and one role each, at most ~3 files, with IDs `<ID>.1`, `<ID>.2`… Write them to the task file or as Linear sub-issues before delegating.
4. Read `.claude/PM-routing.md` if it is not already in context. Write the contract. Delegate subtasks in pipeline order: independent subtasks in parallel, dependent ones in sequence. Every work order states `Commit: yes` (large) or `Commit: no` (small), plus the Linear ID if any.
5. Finish:
   - **Small:** tester → code-reviewer. Then stop with a summary of the changed files and a **suggested commit message**.
   - **Large:** full QA → final-reviewer `READY` → push → open the PR. Locally, set `Status: review`; on Linear, the issue stays In Review.
6. End the session with the result and the next step: `/next` in a fresh session.
