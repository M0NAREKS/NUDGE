# Nudge

Nudge is a Flutter nutrition and coaching app backed by Firebase, Cloud Functions, FatSecret, and Groq.

## Current Scope

- Web auth uses Firebase Auth as the primary identity layer.
- Food search uses `fatsecretSearch` first, then falls back to `foodEstimate`.
- Coaching chat uses `coachChat`.
- App navigation is now shell-based outside auth/onboarding:
  - `Home`
  - `Food`
  - `Coach`
  - `Profile`
- Analytics is sink-based and can write to both Firebase Analytics and Huawei Analytics.
- Notifications are modeled as `remote push + deep link`.

## Architecture

### Providers

- `UserProvider`: auth, session state, profile lifecycle.
- `HealthProvider`: BMR, calorie target, activity-based calculations.
- `FoodProvider`: food search, AI fallback, meal CRUD, daily summary orchestration.

### Bootstrap

Startup is centralized in `lib/services/app_bootstrap.dart`.

Bootstrap responsibilities:

- initialize Firebase
- enable Firestore network
- detect platform capabilities
- initialize analytics sinks
- initialize notification wiring

### Navigation

- Auth and onboarding use named routes.
- Main app flows use the shell in `lib/screens/shell/app_shell_page.dart`.
- Notification deep links are normalized by `NotificationPayload` and `AppRoutes`.

## Backend/API

Cloud Functions are in `functions/`.

Public endpoints:

- `fatsecretSearch`
- `foodEstimate`
- `coachChat`

Rules enforced by the HTTP wrapper:

- shared CORS behavior
- shared auth handling
- standard error envelope
- stable JSON response shape

### Error Envelope

All handled API failures should use:

```json
{
  "error": true,
  "code": "some_code",
  "message": "Human-readable message"
}
```

### LLM Configuration

Groq remains the only LLM provider in this codebase. Models are config-driven.

Supported env/secrets:

- `GROQ_API_KEY`
- `COACH_MODEL`
- `ESTIMATE_MODEL`
- `TRAINING_MODEL`
- `PERFORMANCE_MODEL`

### FatSecret Notes

- FatSecret OAuth credentials are consumed only from Cloud Functions.
- If FatSecret search fails because of upstream IP restrictions, the client should stay usable:
  - FatSecret returns empty/no usable results
  - `FoodProvider` triggers AI fallback
  - manual entry remains available

## Firebase

`firebase.json` is the repo-owned source of truth for:

- Functions source
- Firestore rules
- Hosting output

### Firestore Rules

Rules are defined in `firestore.rules`.

Policy:

- `users/{uid}` and all nested documents are owner-only
- unauthenticated access is denied
- admin access from Cloud Functions is independent from rules

### Push Token Storage

Push tokens are stored below the signed-in user:

`users/{uid}/pushTokens/{provider_platform}`

Document shape:

```json
{
  "provider": "fcm | hms",
  "token": "push-token",
  "platform": "android | ios | web | macos | windows | linux",
  "updatedAt": "server timestamp"
}
```

## Huawei Integration

Huawei support is currently limited to:

- platform capability detection
- Huawei Analytics sink
- Huawei Push token and open-message handling

Not included:

- Huawei Auth
- Huawei Billing

### Android Requirements

- `agconnect-services.json` must be added under `android/app/` for real HMS runtime support.
- `google-services.json` must remain configured for Firebase/FCM builds where applicable.
- Root Gradle config contains a namespace compatibility shim for older plugins.
- App Gradle enables core library desugaring because `flutter_local_notifications` requires it.

## Notifications

Notification payload contract:

```json
{
  "type": "string",
  "route": "home | food | coach | profile",
  "entityId": "optional",
  "title": "optional",
  "body": "optional"
}
```

Core service interface:

- `initialize()`
- `registerToken(provider, token)`
- `handleForegroundMessage(payload)`
- `handleNotificationOpen(payload)`

## Analytics

Primary interface:

- `AppAnalytics.logEvent(name, params)`
- `setUserId(uid)`
- `setUserProperty(key, value)`

Initial event vocabulary:

- `login`
- `sign_up`
- `profile_completed`
- `food_search`
- `food_search_fallback`
- `food_search_result`
- `food_added`
- `coach_chat_opened`
- `coach_reply_received`
- `notification_opened`

## Local Development

Install dependencies:

```bash
flutter pub get
cd functions
npm install
```

Run Flutter web:

```bash
flutter run -d chrome
```

Build outputs:

```bash
flutter build web
flutter build apk --debug
```

### Windows Android run note

If `flutter run` fails on Windows with errors like `Illegal byte sequence` or
`Failed to extract manifest from APK`, the issue is usually the workspace path
containing non-ASCII characters. This repo includes a wrapper that creates an
ASCII-only junction path in `%TEMP%` before running Flutter:

```powershell
powershell -ExecutionPolicy Bypass -File .\tooling\run_android_ascii_path.ps1
```

Optional examples:

```powershell
powershell -ExecutionPolicy Bypass -File .\tooling\run_android_ascii_path.ps1 -FlutterArgs run,-d,windows
powershell -ExecutionPolicy Bypass -File .\tooling\run_android_ascii_path.ps1 -LinkPath C:\nudge_ascii -FlutterArgs run,-d,SM_A235F
```

## API Smoke Check

A lightweight smoke script exists in `functions/smoke_check.js`.

Expected checks:

- CORS preflight returns success
- unauthenticated request returns `401` with standard JSON
- authenticated happy path works when an ID token is supplied

Example:

```bash
cd functions
set NUDGE_BASE_URL=https://us-central1-fitcoach-13e40.cloudfunctions.net
set NUDGE_ID_TOKEN=your_firebase_id_token
npm run smoke:api
```

## Verification

Primary project checks:

```bash
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

## Test Coverage Focus

The current test suite covers:

- FatSecret mapping
- AI fallback behavior
- provider summary rebuilds
- notification payload route normalization
- shell navigation basics
- responsive widget stability on small screens

## Deferred / Internal Only

These modules are not part of the public app surface in this phase:

- `functions/training_agent.js`
- `functions/performance_agent.js`

They remain Groq-backed internal workers and are not exposed as user-facing app endpoints.
