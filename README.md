# It's the Day!

An Android-first countdown app for events, H-7/H-3/H-1/H-0 reminders, a home-screen widget, and calendar import.

## Current scope

- Manual countdowns with local persistence.
- All-day events counted by local calendar day; timed events counted to the second.
- Inexact local notifications for H-7, H-3, H-1, and H-0.
- Read-only device calendar import through Android `CalendarContract`.
- Read-only Google Calendar sync through Google OAuth (`calendar.events.readonly`).
- Native Android home-screen widget for the selected countdown.

Google Calendar sync is intentionally read-only in this MVP. It does not create, edit, or delete events in Google Calendar.

## Verify locally

Use JDK 21 for the current Android toolchain:

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@21
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Enable Google Calendar login

The app does not contain a client secret or a hard-coded OAuth credential. Create the OAuth configuration in the Google Cloud project that owns the app:

1. Enable **Google Calendar API**.
2. Configure the OAuth consent screen and add the testing Google account as a test user while the app is unverified.
3. Create an **Android OAuth client** for package `com.himanusia.itstheday` and the SHA-1 certificate used by the build. `cd android && ./gradlew signingReport` prints the debug certificate.
4. Create or keep a **Web application OAuth client** in the same project.
5. Build with that web client ID supplied out of band:

```bash
flutter run \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
```

The client ID is passed at build time and is not committed. If it is missing, the Calendar screen shows `Needs setup` rather than presenting a login flow that must fail.

## Calendar modes

- **Device**: requests read-only calendar permission and reads calendars already synced to the Android device. This can include Google Calendar, but it is not an in-app Google login.
- **Google**: signs in explicitly, requests `calendar.events.readonly`, calls the Google Calendar API, and labels imported events as `GOOGLE CALENDAR`.

## Android QA

The normal gate order is:

1. `flutter analyze`
2. `flutter test`
3. Android emulator install/smoke test
4. Physical Android device install/visual and interaction QA

The display name and current package/repository slug are **It's the Day!**.

## Persistence status

### Implemented now

- Android events are stored locally as JSON through `SharedPreferencesEventRepository`.
- Widget state is stored in Android `SharedPreferences`.
- `MemoryEventRepository` exists only for deterministic tests/previews.
- There is currently **no server database, account system, realtime sync, group membership, or cross-device state**.

### Target backend

The planned server stack is:

- **Cloudflare Workers + Hono**: typed HTTP/API layer.
- **Better Auth**: server-side identity, Google sign-in, account linking, and session lifecycle mounted in Hono. It is not a Flutter package and never runs with mobile client secrets.
- **Cloudflare D1**: authoritative relational database for users, groups, alarms, memberships, response states, challenge metadata, and audit events.
- **Durable Objects**: per-shared-alarm/group coordination and realtime presence/WebSocket fan-out; not a global singleton.
- **R2**: private object storage for optional proof photos, accessed through short-lived authorized upload/download URLs.
- **Queues/Workflows or scheduled Worker jobs**: notification fan-out, retries, recurring alarms, and missed-response transitions.

Hono is the API framework; it is not the database. D1 is the durable database of record. Better Auth owns the authentication/session tables; application tables for groups, alarms, responses, and challenges remain explicitly modeled and authorized by the API. Local preferences remain only a device cache/fallback after sync exists.

### Flutter authentication boundary

Better Auth is a TypeScript server library, so the Flutter app integrates with it over HTTPS rather than importing a Dart SDK. The planned native flow is:

1. Flutter uses the native Google Sign-In plugin to obtain a Google ID token.
2. Flutter sends that ID token to Better Auth's Google sign-in endpoint over HTTPS.
3. Better Auth verifies the token, creates/links the user in D1, and returns a session.
4. The Flutter client stores only the Better Auth session/bearer token in platform secure storage and attaches it to Hono API requests.
5. The Worker uses Better Auth session validation before reading or mutating private/shared alarm data.

The Better Auth bearer plugin is the intended mobile transport. Browser cookies remain appropriate for a future web client. Google Calendar authorization stays separate and incremental: account sign-in starts with identity scopes, while `calendar.events.readonly` is requested only when the user connects Calendar.

## TODO / not finished

### Cloudflare backend and identity

- [ ] Create a separate `server/` Cloudflare Worker using Hono and Wrangler.
- [ ] Add Better Auth to the Hono Worker and mount `/api/auth/*`.
- [ ] Validate a D1-compatible Better Auth adapter (including schema generation/migrations) against local and deployed Workers before production use.
- [ ] Add Google account authentication/token verification for Flutter without storing the Google client secret in the mobile app.
- [ ] Add the Better Auth bearer plugin and a Flutter `AuthApiClient` using HTTPS plus platform secure storage; do not store auth tokens in `SharedPreferences`.
- [ ] Add D1 migrations for users, groups, memberships, private/shared alarms, per-member responses, device tokens, and append-only audit events.
- [ ] Add server-side authorization: private alarms are owner-only; shared alarms require active group membership and role checks.
- [ ] Add idempotency keys and an outbox/retry path for notification and response events.
- [ ] Add Durable Object coordination per shared alarm/group for realtime state fan-out and conflict-safe updates.
- [ ] Add offline mobile queue and reconciliation against the server authority.

### Shared alarms and family groups

- [ ] Create/join/invite/leave family or group spaces with owner/admin/member roles.
- [ ] Support private alarms and shared alarms with explicit visibility.
- [ ] Track each member independently: pending, fired, snoozed, snooze count, acknowledged, missed, and timestamps.
- [ ] Keep snooze per member; one member's snooze must not move the shared schedule for everyone else.
- [ ] Add FCM/device-token registration and notification delivery/retry.
- [ ] Define timezone, DST, recurrence, missed-alarm, and membership-removal behavior with tests.

### Optional proof challenge

- [ ] Add an optional `challenge_mode` per alarm: `none` or `push_up_photo` in the first slice.
- [ ] Let an alarm owner choose whether a challenge is optional or required for acknowledgement; do not force challenges by default.
- [ ] When enabled, show a challenge after the alarm fires and allow camera capture/upload.
- [ ] Upload photos to a private R2 bucket; store only proof metadata and object references in D1.
- [ ] Let authorized group members see `submitted`, `acknowledged`, `snoozed`, or `missed` state according to policy.
- [ ] Treat a submitted photo as user-provided evidence, not automatic proof that the person physically woke up or completed push-ups.
- [ ] Add retention, deletion, access logs, signed URLs, and abuse/report handling before storing family photos.
- [ ] Do not add AI/photo verification unless explicitly approved; the first slice can use self-attestation or peer review.

### Release and operations

- [ ] Add Cloudflare environment bindings/secrets without committing credentials.
- [ ] Add server integration tests against local D1/Workers test runtime.
- [ ] Add migration/backup/restore and observability runbooks.
- [ ] Run multi-account security tests before calling shared alarms production-ready.
- [ ] Complete physical Android device QA after the backend/auth slice is implemented.
