# UniFacens EcoWallet (Mobile)

Flutter member app for campus kitchen oil rewards.

## Prerequisites

- Flutter SDK 3.38.5+ (see `.fvmrc` if using FVM)
- Local Supabase stack from the repository root (`pnpm dlx supabase start`)

## Supabase configuration

The app reads Supabase settings at compile time via `--dart-define`:

```bash
cd apps/mobile
flutter run \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_ANON_KEY=your-local-anon-key \
  --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

Use the URL and anon key from `pnpm dlx supabase status` after starting the local stack. See [`supabase/README.md`](../../supabase/README.md) for the full bootstrap flow.

Without both defines, the app shows a configuration screen instead of the auth flow.

## Push notifications and device tokens

After sign-in, the app can register the member device token in Supabase `device_tokens` (RLS: members manage their own rows). Express reads those tokens when an admin rejects a disposal and sends FCM/APNs push with a pt-BR reason and deep link `ecowallet://disposal/submit`.

Enable Firebase Messaging on device builds:

```bash
flutter run \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=API_BASE_URL=http://127.0.0.1:3000 \
  --dart-define=ENABLE_PUSH_NOTIFICATIONS=true
```

Add the platform Firebase config files (`google-services.json`, `GoogleService-Info.plist`) before testing on a physical device or emulator. Without `ENABLE_PUSH_NOTIFICATIONS`, token registration is skipped.

**Upsert pattern (Supabase direct):**

```dart
await Supabase.instance.client.from('device_tokens').upsert(
  {'user_id': userId, 'platform': 'android', 'token': fcmToken},
  onConflict: 'user_id,token',
);
```

## Development

```bash
flutter pub get
flutter analyze
flutter test
flutter test --coverage
```

## Project structure

```text
lib/
  core/           # theme, routing, env, shared widgets
  features/
    auth/         # sign-in, sign-up, session
    disposal/     # drop-off selection, photo submit, scoring trigger
    home/         # authenticated shell (placeholder dashboard)
```

Auth and disposal submission use Supabase directly (ADR-003). Confidence scoring triggers `POST /v1/disposals/:id/score` on the Express API with the member JWT.
