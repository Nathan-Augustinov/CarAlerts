# Using CarAlerts without an account

Local mode does not create a Firebase user. The dashboard, car list, and editor
use `CarStore`, which captures either a Firebase UID or the reserved
`device/local` identity. Account storage still supports multiple cars.

`LocalCarStore` persists a single JSON record with the car, its revision token,
local language, and explicit-sign-out preference. iOS uses an atomic file in
Application Support; Android uses a separate SharedPreferences file with a
checked synchronous commit. Mutations are serialized and published only after
persistence succeeds. Local and account cars never share a storage path.

Startup waits for Firebase session restoration. A signed-in user takes priority;
a local car alongside that user opens the transfer decision. Without a user,
a saved local car opens the dashboard unless explicit sign-out was saved.
Continuing without an account also permits an empty dashboard. Cancelling or
failing authentication from that dashboard returns to it.

## Transfer and concurrency

Each local revision has a random token. A Firestore transaction compares the
account car with the exact snapshot displayed in the conflict decision. Changes
require a new decision. Choosing device dates replaces the date data; choosing
account dates leaves the account car unchanged. Registration identity follows
the existing app's trimmed, case-sensitive Firestore document IDs.

The transaction atomically records the token in `_localTransfers` in
`users/{uid}/settings/user_settings`. Existing language/theme fields are merged,
not replaced. This uses the same account-owned settings write permissions as
existing preferences. Account deletion already deletes this settings document.
The token is not authorization or trusted server state.

The local copy is removed only after transaction success and a repeated identity
and revision check. A failed local cleanup can retry using the receipt without
writing the car again, including if another device has subsequently edited,
renamed, or deleted it. Authentication changes leave local data available for a
new decision. Explicit deletion requires a separate confirmation and never
writes account car data. Closing the app is not consent.

## Reminders

Local reminders use `device/local` payload ownership and read the durable local
record without a network request. The existing serialized coordinator cancels
reminders belonging to the previous identity before fetching new data and
retains its existing deduplication behavior. Transfer does not enqueue fresh
catch-up alerts. Taps check ownership before and after reading a car.

## Validation

Run `flutter analyze` and `flutter test`. Tests cover local CRUD/persistence,
limits, routing, authentication cancellation/failure, transfer conflicts and
retries, interrupted cleanup, account changes, explicit deletion, reminder
planning/ownership, and existing account behavior. Fake Firestore tests verify
the transaction callback and stale-snapshot decisions; they do not emulate real
server transaction contention or deployed security rules.

Before release, verify on iOS and Android with the deployed Firebase project:

- Airplane-mode creation, editing, deletion, relaunch, and local language changes.
- Notification permission, actual delivery, and cold-launch taps.
- Provider sign-in cancellation, registration, sign-out, and relaunch.
- Both transfer choices, both duplicate choices, and offline transfer retry.
- A second device changing the account dates while a conflict is displayed.
- Process termination after cloud commit and before local cleanup.

No paid plans, subscriptions, or account restrictions were added.
