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
