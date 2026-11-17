## Release recipe: React Native via Expo EAS

**Tooling:** EAS CLI (`eas-cli`), `eas.json`, EAS Submit and EAS Update.
**Secrets (GitHub):** `EXPO_TOKEN` (expo.dev → Access tokens). App Store Connect API key and Google Play service account are stored **on EAS** with `eas credentials`, not in GitHub.

### Configuration
- `eas.json`: `"cli": { "appVersionSource": "remote" }`; `build.production`: `{ "autoIncrement": true, "channel": "production" }`; `build.preview`: `{ "distribution": "internal", "channel": "preview" }`.
- `submit.production.ios`: `{ "ascAppId": "<id>" }`; `submit.production.android`: `{ "track": "internal" }`.
- The app version comes from `app.config.ts` (read `version` from `package.json` so one bump moves both).
- Runtime version policy for updates: `"runtimeVersion": { "policy": "appVersion" }` unless the project already uses another.

### Shortcuts (`package.json` scripts)
- `release:build`: `eas build --platform all --profile production --non-interactive --auto-submit`
- `release:ios` / `release:android`: the same with one platform
- `release:update`: `eas update --channel production --message "$npm_package_version" --non-interactive`
- `release:preview`: `eas build --platform all --profile preview --non-interactive`

### CI (`.github/workflows/release-eas.yml`)
Trigger on tags `v*`. Ubuntu runner; Node (the project's version) with npm/pnpm cache; `expo/expo-github-action` with `eas-version: latest` and `token: ${{ secrets.EXPO_TOKEN }}`; install; `npm run release:build -- --no-wait`. A second job on pushes to `main` that only touch JS may run `release:update` if the PM enables OTA updates.

### Gotchas
Native changes (new native modules, permissions, SDK upgrades) need a new build; JS-only changes can ship with `eas update` to the same runtime version. Run `npx expo-doctor` before the first release.
