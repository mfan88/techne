#!/usr/bin/env bash
# Collect release credentials once and store them as GitHub Actions secrets (never in the repo).
#   release-setup.sh --targets ios-asc,android-play [--dest .claude] [--no-prompt]
# Targets: ios-asc, android-play, expo-eas, desktop-gha, docker-ghcr
set -euo pipefail
TARGETS=""; DEST=".claude"; PROMPT=1
while [ $# -gt 0 ]; do case "$1" in
  --targets) TARGETS="$2"; shift 2;;
  --dest) DEST="$2"; shift 2;;
  --no-prompt) PROMPT=0; shift;;
  *) echo "unknown option: $1" >&2; exit 1;;
esac; done
[ -n "$TARGETS" ] || { echo "release-setup: --targets required" >&2; exit 1; }

# Prompts read from the terminal, so this works under `curl | bash`.
if [ "$PROMPT" = 1 ] && ! (exec </dev/tty) 2>/dev/null; then PROMPT=0; fi
GH=0
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1 && gh repo view >/dev/null 2>&1; then GH=1; fi

SET_SECRETS=(); SET_VARS=(); MISSING=(); NOTES=()
say() { if [ "$PROMPT" = 1 ]; then printf '%s\n' "$*" >/dev/tty; fi; }
ask() { # ask VAR "prompt" [secret]
  local __v=""
  if [ "$PROMPT" = 1 ]; then
    printf '%s' "$2" >/dev/tty
    if [ "${3:-}" = secret ]; then IFS= read -rs __v </dev/tty || true; printf '\n' >/dev/tty
    else IFS= read -r __v </dev/tty || true; fi
  fi
  printf -v "$1" '%s' "$__v"
}
b64file() { base64 < "$1" | tr -d '\n'; }
expand() { case "$1" in "~/"*) printf '%s' "$HOME/${1#\~/}";; *) printf '%s' "$1";; esac; }
secret() { # secret NAME VALUE
  if [ -z "$2" ]; then MISSING+=("$1"); return; fi
  if [ "$GH" = 1 ] && printf '%s' "$2" | gh secret set "$1" >/dev/null 2>&1; then SET_SECRETS+=("$1"); else MISSING+=("$1"); fi
}
variable() { # variable NAME VALUE
  if [ -z "$2" ]; then MISSING+=("$1 (variable)"); return; fi
  if [ "$GH" = 1 ] && gh variable set "$1" --body "$2" >/dev/null 2>&1; then SET_VARS+=("$1=$2"); else MISSING+=("$1 (variable, value: $2)"); fi
}
secret_file() { # secret_file NAME PATH  (base64 of file)
  local p; p="$(expand "$2")"
  if [ -n "$2" ] && [ -f "$p" ]; then secret "$1" "$(b64file "$p")"; else MISSING+=("$1"); fi
}
secret_raw_file() { local p; p="$(expand "$2")"
  if [ -n "$2" ] && [ -f "$p" ]; then secret "$1" "$(cat "$p")"; else MISSING+=("$1"); fi; }

ASC_DONE=0
asc_key() {
  [ "$ASC_DONE" = 1 ] && return; ASC_DONE=1
  say "App Store Connect API key (App Store Connect → Users and Access → Integrations → Keys)."
  ask ASC_KEY_ID "  Key ID: "; ask ASC_ISSUER_ID "  Issuer ID: "; ask P8 "  Path to AuthKey_<id>.p8: "
  secret ASC_KEY_ID "$ASC_KEY_ID"; secret ASC_ISSUER_ID "$ASC_ISSUER_ID"; secret_file ASC_KEY_P8_BASE64 "$P8"
  local p; p="$(expand "$P8")"
  if [ -n "$P8" ] && [ -f "$p" ] && [ -n "$ASC_KEY_ID" ]; then
    mkdir -p "$HOME/.appstoreconnect/private_keys"
    cp "$p" "$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
    chmod 600 "$HOME/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8"
    NOTES+=("local key: ~/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8")
  fi
}

IFS=',' read -r -a TLIST <<< "$TARGETS"
[ "$PROMPT" = 1 ] && say "" && say "Release credentials for: $TARGETS (press Enter to skip any item; values are never written to the repo)"
[ "$GH" = 1 ] || NOTES+=("gh CLI not authenticated or no GitHub remote: nothing was stored; set the missing names later with gh secret set / gh variable set")
for t in "${TLIST[@]}"; do case "$t" in
  ios-asc)
    asc_key
    ask TEAM "  Apple Team ID: "; variable APPLE_TEAM_ID "$TEAM"
    ask BUNDLE "  iOS bundle ID: "; variable IOS_BUNDLE_ID "$BUNDLE";;
  android-play)
    say "Google Play (service account with release rights; first AAB must be uploaded by hand)."
    ask SA "  Path to service-account JSON: "; secret_raw_file PLAY_SERVICE_ACCOUNT_JSON "$SA"
    ask KS "  Path to upload keystore (.jks/.keystore): "; secret_file ANDROID_KEYSTORE_BASE64 "$KS"
    ask KSP "  Keystore password: " secret; secret ANDROID_KEYSTORE_PASSWORD "$KSP"
    ask KA "  Key alias: "; secret ANDROID_KEY_ALIAS "$KA"
    ask KP "  Key password (Enter if same as keystore): " secret; secret ANDROID_KEY_PASSWORD "${KP:-$KSP}"
    ask PKG "  Android package name: "; variable ANDROID_PACKAGE "$PKG";;
  expo-eas)
    say "Expo EAS (expo.dev → Account settings → Access tokens)."
    ask ET "  EXPO_TOKEN: " secret; secret EXPO_TOKEN "$ET"
    NOTES+=("store the App Store Connect key and Play service account on EAS: npx eas-cli credentials -p ios / -p android");;
  desktop-gha)
    ask SIGNMAC "macOS signing and notarization? [y/N]: "
    if [ "${SIGNMAC:-n}" = y ] || [ "${SIGNMAC:-n}" = Y ]; then
      ask P12 "  Path to Developer ID Application .p12: "; secret_file MACOS_CERT_P12_BASE64 "$P12"
      ask P12P "  .p12 password: " secret; secret MACOS_CERT_PASSWORD "$P12P"
      ask TEAM "  Apple Team ID: "; variable APPLE_TEAM_ID "$TEAM"
      asc_key
    fi
    ask SIGNWIN "Windows code signing with a .pfx? [y/N]: "
    if [ "${SIGNWIN:-n}" = y ] || [ "${SIGNWIN:-n}" = Y ]; then
      ask PFX "  Path to .pfx: "; secret_file WINDOWS_CERT_PFX_BASE64 "$PFX"
      ask PFXP "  .pfx password: " secret; secret WINDOWS_CERT_PASSWORD "$PFXP"
    fi;;
  docker-ghcr)
    NOTES+=("ghcr: no secrets needed (GITHUB_TOKEN). For local pushes: gh auth refresh -s write:packages");;
  *) echo "release-setup: unknown target $t" >&2;;
esac; done

mkdir -p "$DEST"
{
  echo "# Release config (names only; no secret values)"
  echo
  echo "targets: $TARGETS"
  echo "github secrets set: ${SET_SECRETS[*]-none}"
  echo "github variables set: ${SET_VARS[*]-none}"
  echo "missing (set with: gh secret set NAME / gh variable set NAME --body VALUE):"
  for m in "${MISSING[@]-}"; do [ -n "$m" ] && echo "  - $m"; done
  echo "notes:"
  for n in "${NOTES[@]-}"; do [ -n "$n" ] && echo "  - $n"; done
} > "$DEST/release.md"
n=0; for s in "${SET_SECRETS[@]-}"; do [ -n "$s" ] && n=$((n+1)); done
echo "release   targets $TARGETS → $DEST/release.md ($n secrets set)"
