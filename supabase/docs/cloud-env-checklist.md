# Cloud environment variable checklist

Copy values from **Supabase Dashboard → Project Settings → API** (`Project URL`, publishable key, `service_role` **secret**).

## `apps/api` (Express)

| Variable | Required | Notes |
|----------|----------|-------|
| `SUPABASE_URL` | Yes | `https://<project-ref>.supabase.co` |
| `SUPABASE_PUBLISHABLE_KEY` | Yes | JWT verification and RLS-scoped access |
| `SUPABASE_SERVICE_ROLE_KEY` | Yes | Server only; bypasses RLS for admin mutations |
| `PORT` | No | Default `3001` |
| `VISION_API_URL` | No | Confidence scoring |
| `VISION_API_KEY` | No | Confidence scoring |
| `FCM_SERVER_KEY` | No | Android/web push |
| `APNS_*` | No | iOS push when enabled |

Example: `apps/api/.env.example`

## `apps/web` (Next.js admin)

| Variable | Required | Notes |
|----------|----------|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | Yes | Same as `SUPABASE_URL` |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | Yes | Browser-safe |
| `NEXT_PUBLIC_API_BASE_URL` | Yes | Deployed Express URL (no trailing slash) |
| `SUPABASE_SERVICE_ROLE_KEY` | Yes (server) | `/api/admin/photo` signed URLs only |

Example: `apps/web/.env.example`

## `apps/mobile` (Flutter)

Pass at build/run time (not `.env` in repo):

| Dart define | Required | Notes |
|-------------|----------|-------|
| `SUPABASE_URL` | Yes | Cloud project URL |
| `SUPABASE_ANON_KEY` | Yes | Anon key |
| `API_BASE_URL` | Yes | Express base URL for scoring / scratch |
| `ENABLE_PUSH_NOTIFICATIONS` | No | `true` to register `device_tokens` |

Example: `apps/mobile/.env.example` (documentation only)

## Connectivity smoke

- Web: sign in at `/admin/login` with an admin `profiles.role`.
- Mobile: launch with defines; home loads drop-offs from Supabase.
- API: `GET /health` plus authenticated admin route with service role + JWT.
