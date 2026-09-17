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
4. Physical Fold 5 install/visual and interaction QA

The display name and current package/repository slug are **It's the Day!**.
