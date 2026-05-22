# Supabase Local Bootstrap

This directory contains the local Supabase foundation for UniFacens EcoWallet.

## Setup

Run the local stack from the repository root:

```bash
pnpm dlx supabase start
pnpm dlx supabase db reset
pnpm dlx supabase seed buckets
pnpm dlx supabase test db
```

`db reset` applies migrations and loads `seed.sql`. `seed buckets` reconciles the
`disposal-photos` bucket declared in `config.toml`.

## App Environment Variables

Frontend and mobile clients need:

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
```

Server-only code in `apps/api` also needs:

```env
SUPABASE_PUBLISHABLE_KEY=
SUPABASE_SERVICE_ROLE_KEY=
```

Never expose `SUPABASE_SERVICE_ROLE_KEY` in Flutter, Next.js browser code, or any
public environment variable.

## Admin login (web `/admin/login`)

There is **no** migration or seed for a default admin user (intentional — no
hardcoded credentials in the repo).

1. **Supabase Dashboard → Authentication → Users → Add user**  
   Email + password (or invite). Confirm the user if email confirmation is on.
2. **SQL Editor** (or Table Editor → `profiles`) — set role to admin for that user:

```sql
update public.profiles
set role = 'admin'
where id = '<paste-auth-user-uuid>';
```

New auth users get a `profiles` row automatically (`on_auth_user_created_create_profile`).

3. Sign in at `http://localhost:3000/admin/login` with that email and password.

Local DB tests use a fake admin (`admin@example.test`) in `supabase/tests/database/rls.test.sql` only; that user is not created by `seed.sql`.

## Demo mock data (queues, mobile)

`seed.demo.sql` adds three member accounts and eight disposal submissions (verification + audit queues). Idempotent — safe to re-run.

```bash
pnpm dlx supabase db execute --file supabase/seed.demo.sql
```

Demo members (password `demo123456`):

| Email | Role |
|-------|------|
| `maria.demo@ecowallet.test` | member |
| `joao.demo@ecowallet.test` | member |
| `ana.demo@ecowallet.test` | member |

Submissions by status: **4** `submitted`, **1** `under_review`, **2** `awaiting_audit`, **1** `rejected`.

After seeding, refresh `/admin/verificacao` (default filter: `submitted`). Photos use placeholder paths; signed URLs may 404 until files exist in `disposal-photos`.

## Cloud deployment

After local `supabase test db` passes:

1. Read `docs/cloud-deployment-plan.md` (reset vs migrate, rollback, smoke checks).
2. Link the project: `pnpm dlx supabase link --project-ref <ref>`.
3. Push migrations: `pnpm dlx supabase db push`.
4. Seed production defaults: `pnpm dlx supabase db execute --file supabase/seed.production.sql`.
5. Configure apps using `docs/cloud-env-checklist.md` and each app's `.env.example`.
6. Run `scripts/cloud-smoke-check.sql` on the cloud database.
