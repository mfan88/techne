---
name: next
description: Start the next ready task in the queue.
disable-model-invocation: true
---
Pick the next task and start it.

1. **List candidates** in queue order: phase letter, then task number (A1, A2, …, B1).
   - Local: `grep -nE "^(# Phase|## [A-Z][0-9]+ ·|Status:)" tasks/*-tasks.md` (do not read whole files).
   - Linear: the phase projects' issues in Backlog or Todo, ordered the same way.
2. **Skip** any task that is not `backlog`/`todo`, whose dependencies are not all done (or in review with a merged PR), or that shares files with a task in progress.
3. Take the **first** remaining one. If none is ready, report each blocked task in one line (`A4: waits on A3 (review, PR #12 open)`) and stop.
4. Say which ID you picked. Then read `.claude/skills/task/SKILL.md` and follow it from step 2 with that ID. Step 3 decides whether to start here (a fresh session) or hand off to a new one.
