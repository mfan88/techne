## Release recipe: desktop apps via GitHub Actions (macOS, Windows, Linux)

**Tooling:** one workflow with a build matrix, publishing to GitHub Releases.
**Secrets (GitHub), only for platforms that are signed:** macOS `MACOS_CERT_P12_BASE64`, `MACOS_CERT_PASSWORD`, `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64` (notarization); Windows `WINDOWS_CERT_PFX_BASE64`, `WINDOWS_CERT_PASSWORD`. **Variables:** `APPLE_TEAM_ID`.

### Workflow (`.github/workflows/release-desktop.yml`)
- Trigger on tags `v*`; `permissions: contents: write`.
- Matrix: `macos-latest` (arm64, plus `macos-13` for x86_64 if supported), `windows-latest`, `ubuntu-latest` (or the oldest Ubuntu LTS runner, for glibc compatibility).
- Per framework:
  - **Qt/C++ (CMake):** `jurplel/install-qt-action` with the project's Qt version; `cmake --preset release` (or `-DCMAKE_BUILD_TYPE=Release`) and `cmake --build`; package with `macdeployqt` (`.app` → `.dmg`), `windeployqt` (+ the project's installer: NSIS/Inno/WiX, or a zip), and `linuxdeploy` with the Qt plugin (AppImage).
  - **Electron:** `electron-builder --publish always` with `GH_TOKEN`; signing and notarization through electron-builder's env vars.
  - **Tauri:** `tauri-apps/tauri-action`, which builds, signs (when secrets are set) and creates the release.
- macOS signing: import the p12 into a temporary keychain; `codesign --force --options runtime --timestamp --sign "Developer ID Application: …"`; notarize with `xcrun notarytool submit <dmg> --key <p8> --key-id $ASC_KEY_ID --issuer $ASC_ISSUER_ID --wait`; `xcrun stapler staple <dmg>`.
- Windows signing: `signtool sign /fd sha256 /tr <timestamp-url> /td sha256` with the decoded pfx (or Azure Trusted Signing if the project uses it).
- Upload with `softprops/action-gh-release` (draft release, artifacts named `<app>-<version>-<os>-<arch>.<ext>`), plus SHA-256 checksums.

### Shortcuts
`Makefile` (or `package.json` for Electron/Tauri): `release-prepare` → `scripts/release.sh`, `package-local` → a local unsigned build for the current OS.

### Gotchas
Unsigned macOS builds are blocked by Gatekeeper; unsigned Windows builds trigger SmartScreen. Ship unsigned only as a draft for testers. Pin Qt and toolchain versions so builds are reproducible.
