# techne interactive installer. Sourced by install.sh; sets PROFILE LAYERS RELEASE MODE TRACKER
# LTEAM BASE NOPROMPT KEEPMD. Pure bash 3.2+, reads keys from /dev/tty so it works under `curl | bash`.

if [ -n "${NO_COLOR:-}" ]; then C_ACC=""; C_B=""; C_DIM=""; C_OK=""; C_WARN=""; C_RST=""
else C_ACC=$'\033[38;5;209m'; C_B=$'\033[1m'; C_DIM=$'\033[2m'; C_OK=$'\033[32m'; C_WARN=$'\033[33m'; C_RST=$'\033[0m'; fi
UI_STEP=0; UI_DEFAULT=0; UI_ACTIVE=1

_ui_out() { printf '%s' "$*" >/dev/tty; }
_ui_restore() { [ -n "${UI_ACTIVE:-}" ] || return 0; printf '\033[?25h' >/dev/tty 2>/dev/null; stty echo 2>/dev/null </dev/tty; UI_ACTIVE=""; }
_ui_abort() { _ui_restore; printf '\n  Cancelled. Nothing was installed.\n\n' >/dev/tty; exit 130; }
trap '_ui_abort' INT

_ui_key() {
  local k r=""
  IFS= read -rsn1 k </dev/tty || k=q
  case "$k" in
    $'\x1b') IFS= read -rsn2 -t 1 r </dev/tty || true
             case "$r" in '[A'|'OA'|'[D'|'OD') KEY=up;; '[B'|'OB'|'[C'|'OC') KEY=down;; *) KEY=esc;; esac;;
    "") KEY=enter;; " ") KEY=space;; k|K) KEY=up;; j|J) KEY=down;; q|Q) KEY=q;; *) KEY=other;;
  esac
}

_ui_header() {
  _ui_out $'\033[H\033[2J\033[?25l'
  _ui_out "${C_ACC}${C_B}"
  _ui_out "    ▀█▀ █▀▀ █▀▀ █ █ █▄ █ █▀▀"$'\n'
  _ui_out "     █  ██▄ █▄▄ █▀█ █ ▀█ ██▄"$'\n'
  _ui_out "${C_RST}${C_DIM}    τέχνη · the craft of a well-run agent team for Claude Code${C_RST}"$'\n\n'
  local i done_bar="" todo_bar=""
  for ((i=1;i<=UI_TOTAL;i++)); do if ((i<=UI_STEP)); then done_bar="${done_bar}━━"; else todo_bar="${todo_bar}──"; fi; done
  _ui_out "    ${C_ACC}${done_bar}${C_RST}${C_DIM}${todo_bar}  step ${UI_STEP}/${UI_TOTAL}${C_RST}"$'\n\n'
}

_ui_title() { _ui_out "    ${C_B}$1${C_RST}"$'\n'; [ -n "${2:-}" ] && _ui_out "    ${C_DIM}$2${C_RST}"$'\n'; _ui_out $'\n'; }

# ui_select VAR "Title" "hint" "Label|description" ...   → VAR = chosen index (UI_DEFAULT sets the start)
ui_select() {
  local __var=$1 title=$2 hint=$3; shift 3
  local opts=("$@") n=$# cur=$UI_DEFAULT i label desc
  UI_STEP=$((UI_STEP+1))
  while :; do
    _ui_header; _ui_title "$title" "$hint"
    for ((i=0;i<n;i++)); do
      label=${opts[i]%%|*}; desc=""; case "${opts[i]}" in *"|"*) desc=${opts[i]#*|};; esac
      if ((i==cur)); then _ui_out "    ${C_ACC}❯ ${C_B}${label}${C_RST}"$'\n'
      else _ui_out "      ${label}"$'\n'; fi
      [ -n "$desc" ] && _ui_out "      ${C_DIM}${desc}${C_RST}"$'\n'
    done
    _ui_out $'\n'"    ${C_DIM}↑/↓ move · enter select · q quit${C_RST}"$'\n'
    _ui_key
    case $KEY in up) cur=$(((cur-1+n)%n));; down) cur=$(((cur+1)%n));; enter) break;; q|esc) _ui_abort;; esac
  done
  printf -v "$__var" '%s' "$cur"; UI_DEFAULT=0
}

# ui_multi VAR "Title" "hint" "1 0 1" "Label|desc" ...   → VAR = space-separated chosen indices
ui_multi() {
  local __var=$1 title=$2 hint=$3 defs=$4; shift 4
  local opts=("$@") n=$# cur=0 i label desc out="" on=()
  for ((i=0;i<n;i++)); do on[i]=0; done
  i=0; for d in $defs; do on[i]=$d; i=$((i+1)); done
  UI_STEP=$((UI_STEP+1))
  while :; do
    _ui_header; _ui_title "$title" "$hint"
    for ((i=0;i<n;i++)); do
      label=${opts[i]%%|*}; desc=""; case "${opts[i]}" in *"|"*) desc=${opts[i]#*|};; esac
      local box="○"; [ "${on[i]}" = 1 ] && box="${C_OK}◉${C_RST}"
      if ((i==cur)); then _ui_out "    ${C_ACC}❯${C_RST} ${box} ${C_B}${label}${C_RST}"$'\n'
      else _ui_out "      ${box} ${label}"$'\n'; fi
      [ -n "$desc" ] && _ui_out "        ${C_DIM}${desc}${C_RST}"$'\n'
    done
    _ui_out $'\n'"    ${C_DIM}↑/↓ move · space toggle · enter confirm · q quit${C_RST}"$'\n'
    _ui_key
    case $KEY in
      up) cur=$(((cur-1+n)%n));; down) cur=$(((cur+1)%n));;
      space) if [ "${on[cur]}" = 1 ]; then on[cur]=0; else on[cur]=1; fi;;
      enter) break;; q|esc) _ui_abort;;
    esac
  done
  for ((i=0;i<n;i++)); do [ "${on[i]}" = 1 ] && out="$out $i"; done
  printf -v "$__var" '%s' "${out# }"
}

# ui_input VAR "Title" "hint" default
ui_input() {
  local __var=$1 title=$2 hint=$3 def=$4 val=""
  UI_STEP=$((UI_STEP+1))
  _ui_header; _ui_title "$title" "$hint"
  _ui_out $'\033[?25h'"    ${C_ACC}❯${C_RST} "; [ -n "$def" ] && _ui_out "${C_DIM}(${def}) ${C_RST}"
  IFS= read -r val </dev/tty || _ui_abort
  _ui_out $'\033[?25l'
  printf -v "$__var" '%s' "${val:-$def}"
}

_ui_has() { case " $1 " in *" $2 "*) return 0;; esac; return 1; }

tui_run() {
  local t design integ ship mode trk cred md rel_sel lay_sel go i
  local LAYER_NAMES=(flutter react-next react-native swift pytorch-ml docker)
  local REL_NAMES=(ios-asc android-play expo-eas desktop-gha docker-ghcr)
  while :; do
    UI_STEP=0; UI_TOTAL=8; [ -f CLAUDE.md ] && UI_TOTAL=9
    ui_select t "What are you building?" "Sets the stack presets, profiles and release defaults." \
      "Web app|React / Next.js · deploys from your host, no release automation" \
      "Mobile app: React Native / Expo|EAS build, submit and OTA updates" \
      "Mobile app: Flutter|App Store Connect + Google Play" \
      "Mobile app: iOS (Swift)|App Store Connect API + fastlane" \
      "Desktop app|Qt, Electron or Tauri · GitHub Actions → GitHub Releases" \
      "ML / Python service|PyTorch, ML APIs, algorithm programs" \
      "Docker image or quick tool|Small build · released to GHCR" \
      "Custom|Pick stacks and release targets yourself"
    LAYERS=""; RELEASE=""; PROFILE="core"; local ui=1
    case $t in
      0) LAYERS=react-next;;
      1) LAYERS=react-native; RELEASE=expo-eas;;
      2) LAYERS=flutter; RELEASE=ios-asc,android-play;;
      3) LAYERS=swift; RELEASE=ios-asc;;
      4) RELEASE=desktop-gha;;
      5) LAYERS=pytorch-ml; ui=0;;
      6) LAYERS=docker; RELEASE=docker-ghcr; ui=0;;
      7) ui_multi lay_sel "Which stacks?" "Space to toggle. Combine for mixed projects." "0 0 0 0 0 0" \
           "Flutter" "React / Next.js" "React Native / Expo" "Swift (SwiftUI)" "PyTorch / ML / Python" "Docker"
         for i in $lay_sel; do LAYERS="${LAYERS:+$LAYERS,}${LAYER_NAMES[i]}"; done
         UI_TOTAL=$((UI_TOTAL+1));;
    esac

    if [ "$ui" = 1 ]; then
      UI_DEFAULT=$([ "$t" = 4 ] && echo 1 || echo 0)
      ui_select design "Design in Figma with the design agents?" "Eight agents, each editing only its own part of your Figma file." \
        "Yes|research → frames → layout → type → color → accessibility → review → Code Connect" "No|skip the design team"
    else design=1; UI_STEP=$((UI_STEP+1)); fi
    [ "$design" = 0 ] && PROFILE="$PROFILE,design"

    UI_DEFAULT=$([ "$t" = 6 ] && echo 1 || echo 0)
    ui_select integ "Will it talk to third-party APIs or sign-in providers?" "Adds plan-gated integration agents." \
      "Yes|api-integrator + integration-verifier, only after you approve a plan" "No"
    [ "$integ" = 0 ] && PROFILE="$PROFILE,integrations"

    case $t in
      2) ui_multi rel_sel "Which stores?" "Space to toggle." "1 1" "App Store (TestFlight)|App Store Connect API" "Google Play|Play Developer API"
         RELEASE=""; for i in $rel_sel; do RELEASE="${RELEASE:+$RELEASE,}${REL_NAMES[i]}"; done;;
      5) ui_select ship "Ship it as a Docker image?" "Adds the Docker preset and a GHCR release workflow." "Yes|GHCR via GitHub Actions" "No"
         [ "$ship" = 0 ] && { LAYERS="$LAYERS,docker"; RELEASE=docker-ghcr; };;
      7) ui_multi rel_sel "Release automation?" "Leave all off for websites." "0 0 0 0 0" \
           "iOS · App Store Connect" "Android · Google Play" "Expo EAS" "Desktop · GitHub Releases" "Docker · GHCR"
         for i in $rel_sel; do RELEASE="${RELEASE:+$RELEASE,}${REL_NAMES[i]}"; done;;
      *) UI_STEP=$((UI_STEP+1));;
    esac

    UI_DEFAULT=$([ "$t" = 6 ] && echo 1 || echo 0)
    ui_select mode "How should commits work?" "You can change this later in CLAUDE.md and AGENTS.md." \
      "Agents commit (team mode)|subagents commit their work, the main agent opens PRs, up to 2 tasks in parallel" \
      "I commit manually (solo mode)|one task at a time; you review and commit using a suggested message"
    MODE=$([ "$mode" = 0 ] && echo large || echo small)

    ui_select trk "Where do tasks live?" "" "Local task files|tasks/<phase>-tasks.md with A1, A1.1 IDs" "Linear|issues and sub-issues; PRs wait in In Review until you merge"
    if [ "$trk" = 1 ]; then TRACKER=linear; UI_TOTAL=$((UI_TOTAL+1)); ui_input LTEAM "Linear team key" "The prefix of your issue IDs, e.g. ENG in ENG-123." "${LTEAM:-}"
    else TRACKER=local; fi

    if [ -n "$RELEASE" ] && [ "$RELEASE" != docker-ghcr ]; then
      ui_select cred "Add release credentials now?" "Stored only as GitHub Actions secrets with gh; never written to the repo." \
        "Now|you will be asked for each key and password (Enter skips one)" "Later|the installer prints the gh secret set commands"
      NOPROMPT=$cred
    else UI_STEP=$((UI_STEP+1)); NOPROMPT=1; fi

    if [ -f CLAUDE.md ]; then
      ui_select md "This project already has a CLAUDE.md." "" "Replace it|the old one is kept as CLAUDE.md.bak-<time>" "Keep it|install everything else"
      KEEPMD=$md
    else KEEPMD=0; fi

    # Summary
    local row summary="" cmd
    for row in "Profiles|$PROFILE" "Stacks|${LAYERS:-none}" "Release|${RELEASE:-none}" \
               "Commits|$([ "$MODE" = large ] && echo 'agents commit, PRs by the main agent' || echo 'you commit (solo mode)')" \
               "Tasks|$TRACKER${LTEAM:+ ($LTEAM)}" "Base branch|$BASE" \
               "Credentials|$([ -z "$RELEASE" ] && echo n/a || { [ "$NOPROMPT" = 0 ] && echo 'ask now' || echo later; })" \
               "CLAUDE.md|$([ "$KEEPMD" = 1 ] && echo keep || echo 'replace (backup kept)')"; do
      summary="$summary    ${C_DIM}$(printf '%-12s' "${row%%|*}")${C_RST}${row#*|}"$'\n'
    done
    cmd="--profile $PROFILE${LAYERS:+ --layers $LAYERS}${RELEASE:+ --release $RELEASE} --mode $MODE --tracker $TRACKER${LTEAM:+ --linear-team $LTEAM}"
    [ "$BASE" != main ] && cmd="$cmd --base $BASE"
    [ "$NOPROMPT" = 1 ] && [ -n "$RELEASE" ] && cmd="$cmd --no-prompt"
    [ "$KEEPMD" = 1 ] && cmd="$cmd --keep-claude-md"
    local opts=("Install" "Start over" "Cancel") cur=0
    UI_STEP=$UI_TOTAL
    while :; do
      _ui_header; _ui_title "Ready to install" "into $(pwd)"
      _ui_out "$summary"
      _ui_out $'\n'"    ${C_DIM}Same install without the menus:${C_RST}"$'\n'"    ${C_DIM}install.sh $cmd${C_RST}"$'\n\n'
      for ((i=0;i<3;i++)); do if ((i==cur)); then _ui_out "    ${C_ACC}❯ ${C_B}${opts[i]}${C_RST}"; else _ui_out "      ${opts[i]}"; fi; done
      _ui_out $'\n\n'"    ${C_DIM}←/→ · enter${C_RST}"$'\n'
      _ui_key
      case $KEY in up) cur=$(((cur+2)%3));; down) cur=$(((cur+1)%3));; enter) break;; q|esc) _ui_abort;; esac
    done
    case $cur in 0) break;; 1) continue;; 2) _ui_abort;; esac
  done
  _ui_restore
  printf '\033[H\033[2J' >/dev/tty
}
