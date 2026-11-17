## Release recipe: common to every target

- **One entry point.** `scripts/release.sh <major|minor|patch>`: checks a clean tree on the default branch, bumps the version in every version file the project uses (package.json, pubspec.yaml, app.config, Info.plist via agvtool, pyproject.toml, CMakeLists `project(VERSION)`), moves `## [Unreleased]` in CHANGELOG.md to `## [x.y.z] - YYYY-MM-DD`, commits `chore(release): vX.Y.Z`, and creates the tag `vX.Y.Z`. It never pushes; it prints the push command.
- **Shortcuts.** JavaScript projects: `package.json` scripts (`release:prepare`, `release:<target>`). Everything else: `Makefile` targets (`release-prepare`, `release-<target>`), or `justfile` if the project already uses just.
- **CI is triggered by pushing the tag.** Local release commands exist for emergencies and dry runs.
- **Action versions:** pin each action to its current major. Check with `gh api repos/<owner>/<action>/releases/latest --jq .tag_name`; never copy a version from memory.
- **Secrets** are read from GitHub secrets in CI and from env vars or `~/.appstoreconnect` locally. Never write a secret into the repo, a log line or a workflow file. Check that the names exist with `gh secret list` and `gh variable list`.
- **Runbook.** Keep `docs/release.md` current: targets, commands, secrets by name, manual steps (first Play upload, review submission, notarization issues).
