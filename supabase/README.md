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
SUPABASE_SERVICE_ROLE_KEY=
```

Never expose `SUPABASE_SERVICE_ROLE_KEY` in Flutter, Next.js browser code, or any
public environment variable.
