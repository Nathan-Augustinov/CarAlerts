# car_alerts

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Crash reporting

Crashlytics is enabled automatically in release builds. Normal debug/profile builds
turn reporting off and discard unsent test reports. Firebase UID is attached after
sign-in and cleared on sign-out; email, registration numbers, form contents and
notification payloads are not added to reports. Exception messages are reduced to
stable type/code labels while preserving the original stack trace. Platform,
device model, OS version and app version/build are supplied by the SDK.

Reports include screen names, failed operations, and custom action breadcrumbs.
Expected validation/authentication cancellations are not recorded as issues.
Repeated handled failures with the same UID, operation, type/code and first stack
frame are limited to one per minute. Fatal reports are not suppressed. Crashlytics
is not a complete event archive: it retains only a limited number of nonfatal
reports and a bounded breadcrumb log.

### Test locally

```sh
flutter run --dart-define=ENABLE_CRASHLYTICS=true
```

Sign in, open Settings, and use the **Crashlytics development tests** controls:

1. Record a handled error; the app should stay open.
2. Trigger an uncaught error to verify the global Dart handler.
3. Trigger a native test crash (confirmation required); reopen the same test build.
4. In Firebase Console > Crashlytics, select the corresponding Android/iOS app.
   Verify stack frames, logs, screen, operation, environment=development_test,
   and the signed-in user's UID. Reports can take several minutes to appear.
5. Sign out and repeat: the new report must have no account UID.

For iOS native crash tests, disconnect the debugger and launch the installed test
app from the home screen before triggering the crash. Reopen it afterward. Keep
the test flag enabled through that relaunch; launching a normal development build
instead discards pending test reports. If replacing an existing test/release install
with normal development, uninstall the test build first to clear the native SDK's
persisted collection override and pending crash session before startup.

The controls never appear in release builds. Release mode itself can be checked
with `flutter run --release`; its reports are labelled environment=release.
To investigate a user complaint, find their email in Firebase Authentication,
copy the UID, and compare it with the User ID on Crashlytics events. Device delivery
and console visibility must be verified with the steps above, not inferred from
unit tests or a successful build.

### Release symbols

Android applies the Crashlytics Gradle plugin for build IDs and mapping uploads.
iOS uses Swift Package Manager and a final **Crashlytics Upload Symbols** build
phase; do not remove it. Device builds upload Flutter/native dSYMs using the
resolved Firebase SDK and `ios/firebase_app_id_file.json`. Simulator builds upload Runner.app.dSYM, including the debug dylib symbols. Resolve Swift packages in Xcode if the uploader is missing.

Normal `flutter build apk --release` requires no extra Dart symbol command. If
using `--split-debug-info` or `--obfuscate` for Android, retain the generated symbols
and upload them before testing/distributing that build:

```sh
firebase crashlytics:symbols:upload --app=FIREBASE_ANDROID_APP_ID path/to/symbols
```

Use the `mobilesdk_app_id` from `android/app/google-services.json`. Increment the
version/build in `pubspec.yaml` for distributed builds so reports can be attributed
to the correct release.
