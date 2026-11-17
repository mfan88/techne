---
name: roster
description: List the agents on this project's roster with their models.
disable-model-invocation: true
---
Agents installed for this project:

!`for f in .claude/agents/*.md; do n=$(sed -n 's/^name: *//p' "$f" | head -1); m=$(sed -n 's/^model: *//p' "$f" | head -1); e=$(sed -n 's/^effort: *//p' "$f" | head -1); d=$(sed -n 's/^description: *//p' "$f" | head -1 | tr -d '"' | cut -d. -f1); echo "$n | $m | ${e:-default} | $d"; done 2>/dev/null; echo "---"; cat .claude/.techne.lock 2>/dev/null`

Show this as a table (Agent | Model | Effort | Role), grouped as Design, Build, Integrations, QA, Gate/Release, using the names. Keep the role text as given. After the table, add one line with the profile, layers and release targets from the lock file. Add nothing else.
