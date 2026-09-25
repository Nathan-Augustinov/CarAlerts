#!/bin/sh
set -eu
# Flutter's Swift Package Manager build uses Xcode's resolved Firebase SDK.
crashlytics_dir="${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics"
if [ ! -x "$crashlytics_dir/upload-symbols" ]; then
  echo "error: Firebase Crashlytics upload-symbols is missing; resolve Swift packages in Xcode."
  exit 1
fi
if [ "${PLATFORM_NAME:-}" = "iphonesimulator" ]; then
  # The Flutter uploader's device path does not cover simulator debug dylibs.
  # Runner.app.dSYM contains both Runner and Runner.debug.dylib symbols.
  simulator_dsym="${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}"
  if [ ! -d "$simulator_dsym" ]; then
    echo "error: Missing simulator dSYM: $simulator_dsym. Enable DWARF with dSYM File."
    exit 1
  fi
  firebase_app_id=$(/usr/libexec/PlistBuddy -c 'Print :GOOGLE_APP_ID' "$PROJECT_DIR/Runner/GoogleService-Info.plist")
  "$crashlytics_dir/upload-symbols" -ai "$firebase_app_id" -p ios "$simulator_dsym"
else
  "$crashlytics_dir/upload-symbols" --flutter-project "$PROJECT_DIR/firebase_app_id_file.json"
fi
