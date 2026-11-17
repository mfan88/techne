## Release recipe: Android via Google Play Developer API (Flutter, native Android)

**Tooling:** fastlane `supply` (`upload_to_play_store`), local and on an Ubuntu runner.
**Secrets (GitHub):** `PLAY_SERVICE_ACCOUNT_JSON`, `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`. **Variables:** `ANDROID_PACKAGE`.

### Build
- Signing: `android/key.properties` generated at build time from the secrets (never committed; gitignored), read by `build.gradle(.kts)` `signingConfigs.release`. In CI decode `ANDROID_KEYSTORE_BASE64` to a temp file.
- Flutter: `flutter build appbundle --release --build-number=<n>`. Native: `./gradlew bundleRelease`.
- Version code: strictly increasing, shared rule with iOS build numbers (e.g. `git rev-list --count HEAD`).

### Lanes
- `android internal`: build → `upload_to_play_store(track: "internal", aab: <path>, json_key_data: ENV["PLAY_SERVICE_ACCOUNT_JSON"], release_status: "completed")`.
- `android promote`: `upload_to_play_store(track: "internal", track_promote_to: "production", skip_upload_aab: true, rollout: "0.1")`; only with PM approval.

### Shortcuts
`Makefile`: `release-android` → `bundle exec fastlane android internal`, `promote-android` → `bundle exec fastlane android promote`.

### CI (`.github/workflows/release-android.yml`)
Trigger on tags `v*`. `runs-on: ubuntu-latest`; Java (temurin, the version Gradle needs); Flutter for Flutter projects; Ruby + bundler; write the keystore and `key.properties`; run the lane. Cache Gradle and pub.

### Gotchas
The **first** AAB for a new app must be uploaded by hand in the Play Console; the API only works after that. The service account must be invited in Play Console → Users and permissions with release rights for this app.
