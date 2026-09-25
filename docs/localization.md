# Localization

The app uses Flutter's `flutter_localizations` and `gen-l10n`. Before sign-in,
the phone's primary language selects Romanian for any `ro` locale (including
Romania and Moldova); other languages select English. This initial locale is
available immediately on the welcome screen.

Saved account preferences always take priority. On sign-in/account restoration,
a missing language is initialized from the phone; existing values, including
previously defaulted English, stay unchanged. Manual changes in Settings update
the app, pending reminders, and Firestore. Signing out returns to the initial
phone-based language; signing back in restores the account preference. Phone
language changes do not overwrite a saved account preference. Firestore's mobile
cache supports offline reads. OS-owned dialogs follow the operating system's own
language rules.

## Strings

Edit `lib/l10n/app_en.arb` and `lib/l10n/app_ro.arb` together. These JSON-based ARB
files are the source of truth; no spreadsheet is needed. Run `flutter gen-l10n`
after edits. Generated `app_localizations*.dart` files are checked in for reliable
analysis and must not be edited manually. Flutter also generates them on builds.

Use `AppLocalizations.of(context)!` in widgets. Use typed placeholders and ICU
plural messages for dynamic text; Romanian has `one`, `few`, and `other` forms.
Use `localizedDate` for displayed dates. Store dates and database keys in their
existing stable formats. Car registration numbers and custom expiry names are
user content and are not translated. Use complete messages rather than assembling
translated word fragments.

A translation platform or spreadsheet export can be added when non-developer
translators need it; keep ARB as the build input to avoid two competing catalogs.
Bundled copy changes require an app release.

## Firestore

Path: `users/{uid}/settings/user_settings`

Field: `language`, string enum `en` / `ro`, initial value based on the phone (`ro` or `en`).

Existing settings receive the default lazily on sign-in/app account restoration,
using a transaction and merge. Existing preferences are preserved. Missing language uses the initial phone-based locale; unsupported saved codes
render English. Language changes merge only this
field. The listener picks up changes made on other signed-in devices. No bulk
migration is needed. The repository's `firestore.rules` allows each authenticated user to read and
write arbitrary fields in their own settings documents. New preferences do not
require rules changes. Car validation stays separate. Publish this file in the
Firebase console's Firestore Rules tab; saving it locally does not deploy it.
Settings are user-controlled and must not contain trusted authorization or billing
state.

## Verification

Run `flutter analyze` and `flutter test`. Localization tests cover catalog parity,
Romanian plurals, default backfill, persistence, account switching, the language
selector, date formatting, and rescheduling translated reminders without new IDs.
On a device, also check both languages with large text, offline changes, restart,
and notification delivery. The native launch artwork remains the CarAlerts brand.
