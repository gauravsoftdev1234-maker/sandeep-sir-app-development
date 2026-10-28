# SevaHub Partner

Flutter app for SevaHub service partners: see nearby job requests, accept and
complete them, and stay reachable through push notifications.

- Package: `com.partnerapnaservice.app`
- Backend: `https://appadmin.atharvaservices.com`

## Running it

```bash
flutter pub get
flutter run
```

Tests:

```bash
flutter test
```

## What is in here

| Area | Where |
|---|---|
| Job feed, detail and status changes | `lib/features/bookings/` |
| Sign-in, registration, onboarding | `lib/features/auth/` |
| Dashboard and its header | `lib/features/home/` |
| Push notifications and badge count | `lib/core/push/` |
| Location gate and reverse geocoding | `lib/core/location/` |
| Weather, sky and festival theming | `lib/core/weather/`, `lib/core/theme/` |

A few behaviours worth knowing before changing them:

- **Location is mandatory.** Nothing past the splash opens without it, not even
  sign-in — jobs are matched to where the partner is.
- **The header dresses itself** from the clock first (blue sky, golden dusk,
  dark sky with moon and stars), with rain, storm and snow overriding it.
- **A push refreshes the job feed**, so a new job lands without a manual pull.

## Release builds

Signing credentials live in `android/key.properties` and
`android/app/sevahub-release.jks`. Both are deliberately **not** in this
repository. Without them a release build silently falls back to the debug key,
which the Play Console rejects — so keep a backup somewhere safe.

```bash
flutter build appbundle --release
```

After changing the signing key, add its SHA-1 and SHA-256 to the Firebase
console, or push notifications stop arriving in the published build.
