## Release recipe: iOS via App Store Connect API (Swift, Flutter iOS)

**Tooling:** fastlane (`Gemfile` + `fastlane/Fastfile`), run locally and on a macOS GitHub Actions runner.
**Secrets (GitHub):** `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64`. **Variables:** `APPLE_TEAM_ID`, `IOS_BUNDLE_ID`.
**Local key:** `~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8` (written by release-setup).

### Build
- Signing: Xcode automatic (cloud) signing authenticated with the API key: pass `-allowProvisioningUpdates -authenticationKeyPath <p8> -authenticationKeyID $ASC_KEY_ID -authenticationKeyIssuerID $ASC_ISSUER_ID` through `build_app(xcargs: ...)`. Use fastlane `match` instead only if the project already has a certificates repo.
- Swift: `build_app(scheme:, export_method: "app-store")`.
- Flutter: `flutter build ios --release --no-codesign --build-number=<n>` first, then `build_app(workspace: "ios/Runner.xcworkspace", scheme: "Runner", export_method: "app-store")`.
- Build number: `latest_testflight_build_number + 1` (or `git rev-list --count HEAD`); never reuse one.

### Lanes
- `ios beta`: API key → build → `upload_to_testflight(skip_waiting_for_build_processing: true, changelog: <notes>)`.
- `ios release`: same build → `upload_to_app_store(submit_for_review: false, skip_screenshots: true)`; review submission stays manual unless the PM says otherwise.
- API key in lanes: `app_store_connect_api_key(key_id: ENV["ASC_KEY_ID"], issuer_id: ENV["ASC_ISSUER_ID"], key_content: ENV["ASC_KEY_P8_BASE64"], is_key_content_base64: true)`.

### Shortcuts
`Makefile`: `release-ios-beta` → `bundle exec fastlane ios beta`, `release-ios` → `bundle exec fastlane ios release`.

### CI (`.github/workflows/release-ios.yml`)
Trigger on tags `v*`. `runs-on: macos-latest`; checkout with `fetch-depth: 0`; select the Xcode version the project uses; Ruby + `bundle install`; Flutter setup for Flutter projects; run `bundle exec fastlane ios beta` with the secrets as env. Cache CocoaPods and the Flutter pub cache.

### Gotchas
The app record must already exist in App Store Connect. The API key needs the App Manager role. Export compliance (`ITSAppUsesNonExemptEncryption`) in Info.plist avoids a manual prompt per build.
