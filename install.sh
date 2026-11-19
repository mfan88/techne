#!/usr/bin/env bash
# techne: install an agent team into a Claude Code project.
#   curl -fsSL https://raw.githubusercontent.com/mfan88/techne/main/install.sh | bash
# With no options in a terminal, an interactive installer asks what you are building.
# Options (any of these skips the menus):
#   --sections LIST       agent sections: design, api, build, testing, review, docs (default: all)
#                         aliases: core = build,testing,review,docs · integrations = api
#   --profile LIST        same as --sections
#   --ref REF             git ref/tag to install (default: main)
#   --from DIR            install from a local checkout instead of GitHub
#   --global              install into ~/.claude instead of ./.claude
#   --figma-server NAME   MCP server name your Figma server is registered under (default: figma)
#   --layers LIST         comma-separated stack presets from layers/ (e.g. react-next,docker),
#                         written to .claude/LAYERS.md for the builder agents
#   --release LIST        release targets: ios-asc, android-play, expo-eas, desktop-gha, docker-ghcr
#                         (omit for websites). Adds release-manager, its recipes, and prompts for credentials
#   --no-prompt           skip credential prompts (CI, cloud sessions)
#   --mode small|large    small: docker images/quick tools, user commits (default: large)
#   --tracker local|linear  where tasks live (default: local)
#   --linear-team KEY     Linear team key (with --tracker linear)
#   --linear-server NAME  MCP server name for Linear tools (default: linear)
#   --base BRANCH         base branch (default: main)
#   --keep-claude-md      do not replace ./CLAUDE.md (it is backed up otherwise)
#   --yes                 no menus; use defaults for anything not given
#   --dry-run             print what would be installed
set -euo pipefail
REPO="${TECHNE_REPO:-mfan88/techne}"
REF="main"; PROFILE="all"; FROM=""; DEST=".claude"; FIGMA="figma"; DRY=0; LAYERS=""; RELEASE=""; NOPROMPT=0; MODE="large"; TRACKER="local"; LTEAM=""; LSERVER="linear"; BASE=""; KEEPMD=0; GLOBAL=0; CFG=0
while [ $# -gt 0 ]; do case "$1" in
  --profile|--sections) CFG=1; PROFILE="$2"; shift 2;;
  --ref) REF="$2"; shift 2;;
  --from) FROM="$2"; shift 2;;
  --global) CFG=1; DEST="$HOME/.claude"; GLOBAL=1; shift;;
  --figma-server) FIGMA="$2"; shift 2;;
  --layers) CFG=1; LAYERS="$2"; shift 2;;
  --release) CFG=1; RELEASE="$2"; shift 2;;
  --no-prompt) CFG=1; NOPROMPT=1; shift;;
  --mode) CFG=1; MODE="$2"; shift 2;;
  --tracker) CFG=1; TRACKER="$2"; shift 2;;
  --linear-team) CFG=1; LTEAM="$2"; shift 2;;
  --linear-server) LSERVER="$2"; shift 2;;
  --base) BASE="$2"; shift 2;;
  --keep-claude-md) CFG=1; KEEPMD=1; shift;;
  --yes|-y) CFG=1; shift;;
  --dry-run) DRY=1; shift;;
  -h|--help) sed -n '2,28p' "$0" 2>/dev/null || true; exit 0;;
  *) echo "unknown option: $1" >&2; exit 1;;
esac; done

case "$MODE" in small|large) ;; *) echo "--mode must be small or large" >&2; exit 1;; esac
case "$TRACKER" in local|linear) ;; *) echo "--tracker must be local or linear" >&2; exit 1;; esac

if [ -z "$BASE" ]; then
  BASE=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || true)
  [ -n "$BASE" ] || BASE=main
fi
INTERACTIVE=0
if [ "$CFG" = 0 ] && (exec </dev/tty) 2>/dev/null && [ -z "${CI:-}" ]; then INTERACTIVE=1; fi

TMP=$(mktemp -d); trap 'rm -rf "$TMP"; type _ui_restore >/dev/null 2>&1 && _ui_restore' EXIT
[ "$INTERACTIVE" = 1 ] && printf '  Fetching techne…\n' >/dev/tty
AUTH=(); [ -n "${GITHUB_TOKEN:-}" ] && AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN")
if [ -n "$FROM" ]; then
  SRC="$FROM"; SHA="local"
else
  curl -fsSL ${AUTH[@]+"${AUTH[@]}"} "https://api.github.com/repos/$REPO/tarball/$REF" \
    | tar -xz -C "$TMP" --strip-components=1
  SRC="$TMP"
  SHA=$(curl -fsSL ${AUTH[@]+"${AUTH[@]}"} "https://api.github.com/repos/$REPO/commits/$REF" \
    | grep -m1 '"sha"' | cut -d'"' -f4 || echo unknown)
fi

log() { [ "$INTERACTIVE" = 1 ] || echo "$@"; }
if [ "$INTERACTIVE" = 1 ]; then
  # shellcheck source=/dev/null
  . "$SRC/tui/tui.sh"
  tui_run
fi

items=()
if [ "$PROFILE" = "all" ]; then
  for f in "$SRC"/agents/*.md; do n=$(basename "$f" .md); [ "$n" = release-manager ] || items+=("$n"); done
  for d in "$SRC"/skills/*/; do items+=("$(basename "$d")"); done
else
  # Aliases from earlier versions: core = build,testing,review,docs; integrations = api.
  PROFILE=$(printf '%s' "$PROFILE" | perl -pe 's/\bcore\b/build,testing,review,docs/g; s/\bintegrations\b/api/g')
  IFS=',' read -r -a profs <<< "$PROFILE"
  for pf in "${profs[@]}"; do
    [ "$pf" = none ] && continue
    [ -f "$SRC/profiles/$pf.txt" ] || { echo "no profile: $pf" >&2; exit 1; }
    while IFS= read -r line || [ -n "$line" ]; do
      line="${line%%#*}"; line="$(echo "$line" | tr -d '[:space:]')"
      [ -z "$line" ] && continue
      case " ${items[*]-} " in *" $line "*) ;; *) items+=("$line");; esac
    done < "$SRC/profiles/$pf.txt"
  done
fi

if [ -n "$RELEASE" ] && [ "$RELEASE" != none ]; then
  case " ${items[*]-} " in *" release-manager "*) ;; *) items+=("release-manager");; esac
fi

# Which sections ended up installed (drives CLAUDE.md, PM-routing, AGENTS.md and /task).
has() { case " ${items[*]-} " in *" $1 "*) return 0;; esac; return 1; }
SECTIONS=""
has canvas-designer && SECTIONS="$SECTIONS design"
has api-integrator && SECTIONS="$SECTIONS api"
{ has feature-builder || has logic-builder || has component-builder || has wiring-builder; } && SECTIONS="$SECTIONS build"
{ has tester || has test-writer; } && SECTIONS="$SECTIONS testing"
{ has final-reviewer || has code-reviewer; } && SECTIONS="$SECTIONS review"
has docs-writer && SECTIONS="$SECTIONS docs"
has release-manager && SECTIONS="$SECTIONS release"
SECTIONS="${SECTIONS# }"
export SECTIONS

# Files that are not for Claude Code: Codex metadata everywhere, maintainer docs in color-expert.
EXCLUDES=(--exclude 'openai.yaml' --exclude '.gitignore' --exclude '.DS_Store')
COLOR_EXPERT_EXTRA=(--exclude 'CLAUDE.md' --exclude 'README.md' --exclude 'ROADMAP.md'
                    --exclude 'MAINTENANCE.md' --exclude 'SECURITY.md' --exclude 'evals' --exclude 'scripts')

[ "$DRY" = 1 ] || mkdir -p "$DEST/agents" "$DEST/skills"
for it in "${items[@]}"; do
  if [ -f "$SRC/agents/$it.md" ]; then
    log "agent  $it"
    [ "$DRY" = 1 ] && continue
    cp "$SRC/agents/$it.md" "$DEST/agents/$it.md"
    [ "$FIGMA" = figma ] || perl -pi -e "s/mcp__figma__/mcp__${FIGMA}__/g" "$DEST/agents/$it.md"
    [ "$LSERVER" = linear ] || perl -pi -e "s/mcp__linear__/mcp__${LSERVER}__/g" "$DEST/agents/$it.md"
  elif [ -d "$SRC/skills/$it" ]; then
    log "skill  $it"
    [ "$DRY" = 1 ] && continue
    rm -rf "$DEST/skills/$it"; mkdir -p "$DEST/skills/$it"
    ex=("${EXCLUDES[@]}"); [ "$it" = color-expert ] && ex+=("${COLOR_EXPERT_EXTRA[@]}")
    tar -C "$SRC/skills/$it" "${ex[@]}" -cf - . | tar -C "$DEST/skills/$it" -xf -
    rmdir "$DEST/skills/$it/agents" 2>/dev/null || true
  else
    echo "warn   $it not found in roster" >&2
  fi
done

if [ -n "$LAYERS" ]; then
  out="$DEST/LAYERS.md"
  [ "$DRY" = 1 ] || printf '# Layers\n\nInstalled by techne. Project AGENTS.md → Layers overrides anything here.\n' > "$out"
  IFS=',' read -r -a stacks <<< "$LAYERS"
  for s in "${stacks[@]}"; do
    [ -f "$SRC/layers/$s.md" ] || { echo "warn   no layer preset: $s" >&2; continue; }
    log "layers $s"
    [ "$DRY" = 1 ] || { printf '\n' >> "$out"; cat "$SRC/layers/$s.md" >> "$out"; }
  done
fi

if [ -n "$RELEASE" ] && [ "$RELEASE" != none ]; then
  IFS=',' read -r -a rts <<< "$RELEASE"
  for r in common "${rts[@]}"; do
    [ -f "$SRC/release/recipes/$r.md" ] || { echo "warn   no release recipe: $r" >&2; continue; }
    log "recipe $r"
    [ "$DRY" = 1 ] || { mkdir -p "$DEST/release"; cp "$SRC/release/recipes/$r.md" "$DEST/release/$r.md"; }
  done
  if [ "$DRY" != 1 ]; then
    pr=(); [ "$NOPROMPT" = 1 ] && pr=(--no-prompt)
    bash "$SRC/release/release-setup.sh" --targets "$RELEASE" --dest "$DEST" ${pr[@]+"${pr[@]}"}
  fi
fi

# Main-agent files: CLAUDE.md, commands, routing guide, templates (project installs only).
if [ "$GLOBAL" = 0 ]; then
  COMMITS=agents; [ "$MODE" = small ] && COMMITS=user
  LIN=""; [ "$TRACKER" = linear ] && LIN="(team \`${LTEAM:-<set team>}\`, MCP server \`$LSERVER\`)"
  fill() { perl -0pe 's{<!-- if:(!?)([a-z]+) -->\n(.*?)<!-- endif -->\n}{ my ($n,$s,$b)=($1,$2,$3); my $on=(" $ENV{SECTIONS} " =~ / \Q$s\E /) ? 1 : 0; ($n ? !$on : $on) ? $b : "" }gse' "$1" | perl -0pe 's/^##+ [^\n]+\n\n(?=##? |\z)//mg; s/\n{3,}/\n\n/g' | perl -pe "s|\{\{SECTIONS\}\}|${SECTIONS:-none}|g; s|\{\{MODE\}\}|$MODE|g; s|\{\{TRACKER\}\}|$TRACKER|g; s|\{\{LINEAR\}\}|$LIN|g; s|\{\{BASE\}\}|$BASE|g; s|\{\{LAYERS\}\}|${LAYERS:-none}|g; s|\{\{RELEASE\}\}|${RELEASE:-none}|g; s|\{\{COMMITS\}\}|$COMMITS|g"; }
  log "main   CLAUDE.md ($MODE, $TRACKER), /task /next /roster, PM-routing"
  if [ "$DRY" != 1 ]; then
    for c in task next roster; do mkdir -p "$DEST/skills/$c"; fill "$SRC/claude/commands/$c/SKILL.md" > "$DEST/skills/$c/SKILL.md"; done
    fill "$SRC/templates/PM-routing.md" > "$DEST/PM-routing.md"
    mkdir -p "$DEST/templates"
    cp "$SRC/templates/integration-plan.md" "$DEST/templates/"
    fill "$SRC/templates/AGENTS-roster-sections.md" > "$DEST/templates/AGENTS-roster-sections.md"
    if [ "$KEEPMD" = 0 ]; then
      if [ -f CLAUDE.md ]; then b="CLAUDE.md.bak-$(date +%Y%m%d-%H%M%S)"; mv CLAUDE.md "$b"; echo "backup CLAUDE.md → $b (move any project facts into AGENTS.md)"; fi
      fill "$SRC/claude/CLAUDE.md" > CLAUDE.md
    fi
    if [ ! -f AGENTS.md ]; then { echo "# AGENTS.md"; echo; fill "$SRC/templates/AGENTS-roster-sections.md" | sed '1,2d'; } > AGENTS.md; echo "create AGENTS.md from template (fill it in)"; fi
  fi
fi

[ "$DRY" = 1 ] && exit 0
printf 'repo=%s\nref=%s\nsha=%s\nprofile=%s\nfigma_server=%s\nlayers=%s\nrelease=%s\nmode=%s\ntracker=%s\nsections=%s\n' "$REPO" "$REF" "$SHA" "$PROFILE" "$FIGMA" "$LAYERS" "$RELEASE" "$MODE" "$TRACKER" "$SECTIONS" > "$DEST/.techne.lock"
na=$(ls "$DEST/agents" 2>/dev/null | wc -l | tr -d ' '); ns=$(ls "$DEST/skills" 2>/dev/null | wc -l | tr -d ' ')
if [ "$INTERACTIVE" = 1 ]; then
  printf '\n  \033[32m✓\033[0m Installed %s agents and %s skills into %s  \033[2m(sections: %s · %s)\033[0m\n' "$na" "$ns" "$DEST" "${SECTIONS:-none}" "${SHA:0:7}"
else
  echo "Installed sections '${SECTIONS:-none}' into $DEST (${SHA:0:7})"
fi
if [ "$GLOBAL" = 0 ]; then
  cat <<NEXT

Next steps
  1. Fill in AGENTS.md (commands, conventions${LAYERS:+, stack details}).
  2. Connect the MCP servers you use: Figma, Mobbin, Linear (claude mcp add …).
  3. Open Claude Code here, plan your first phase, then run /next.
NEXT
  if [ -n "$RELEASE" ]; then echo "  4. Then give release-manager its one-time setup work order (missing secrets: .claude/release.md)."; fi
fi
