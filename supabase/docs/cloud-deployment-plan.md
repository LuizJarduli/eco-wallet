# Cloud Supabase Deployment Plan (Task 13)

## Approval checkpoint (2026-05-20)

| Item | Decision |
|------|----------|
| Cloud data value | **Disposable** — all legacy `public` tables had **0 rows** at snapshot time |
| Strategy | **Reset** — drop legacy prototype schema, apply PRD-aligned migrations |
| Backup | Not required for empty tables; use Supabase Dashboard backup before any future destructive change |
| Authorization | Compozy task_13 execution (user-approved run) |

## 13.1 Cloud snapshot (before deploy)

### Legacy schema (removed)

| Object | Notes |
|--------|--------|
| `users`, `wallets`, `disposals`, `collection_points`, … | Pre-PRD prototype; incompatible enums (`PRE_ANALYSIS`, etc.) |
| Row counts | **0** on every table |
| `supabase_migrations` | Not present / empty before MCP apply |
| Storage buckets | **None** |

### Target schema (PRD-aligned)

Matches `supabase/migrations/`:

1. `20260517205800_cloud_reset_legacy_schema.sql`
2. `20260517205900_init_campus_kitchen_oil_rewards.sql`
3. `20260518000000_disposal_admin_audit_rpc.sql`
4. `20260518025500_add_disposal_capture_coordinates.sql`
5. `20260520000000_scratch_play_rpc.sql`

## 13.2 Reset vs migrate

**Chosen: reset.** Incremental migration from legacy tables to PRD tables would require data mapping and enum renames with no production data to preserve.

## 13.3 Link local CLI to cloud

```bash
pnpm dlx supabase login
pnpm dlx supabase link --project-ref <YOUR_PROJECT_REF>
```

MCP-connected deploy for this run used the linked Supabase project (see Dashboard → Settings → API for URL and keys).

## 13.4–13.5 Apply migrations and seed

```bash
# After link (or use Dashboard SQL + MCP migrations)
pnpm dlx supabase db push
pnpm dlx supabase db execute --file supabase/seed.production.sql
```

Production seed is idempotent (`seed.production.sql`): active reward rule (10 coins/L, 1 L min), UniFacens drop-off, scratch campaign.

## 13.6 Environment variables

See [cloud-env-checklist.md](./cloud-env-checklist.md). Copy from Supabase Dashboard → Settings → API.

| App | Required |
|-----|----------|
| `apps/api` | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, optional `VISION_*`, `FCM_*`, `PORT` |
| `apps/web` | `NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `NEXT_PUBLIC_API_BASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (server only) |
| `apps/mobile` | `--dart-define=SUPABASE_URL`, `SUPABASE_ANON_KEY`, `API_BASE_URL` |

Never commit real keys. Use host-specific `.env` / CI secrets.

## 13.7 Cloud smoke evidence (2026-05-20)

Run `supabase/scripts/cloud-smoke-check.sql` against cloud (or review MCP evidence below).

| Check | Result |
|-------|--------|
| `disposal_status` enum | `submitted,under_review,approved,awaiting_audit,rewarded,rejected` |
| Active `reward_rules` | `coins_per_liter=10`, `min_liters=1.00` |
| Active drop-off / campaign | 1 each |
| `disposal-photos` bucket | Present, private, 10 MB, image MIME types |
| `disposal_submissions` RLS | INSERT + SELECT only (no member UPDATE) |
| Storage policies | SELECT + INSERT under `{userId}/` prefix |
| Admin RPCs | `approve_disposal_admin`, `audit_disposal_collection_admin`, `play_scratch_card_member` → `service_role` only |

### Manual RLS checks (authenticated clients)

1. Member inserts own row with `status=submitted` → allowed.
2. Member `UPDATE` submission to `rewarded` → denied (no policy).
3. Admin reads all submissions via anon/authenticated client → SELECT allowed; status change via client → denied.
4. Upload to `disposal-photos/{otherUserId}/x.jpg` → denied; own prefix → allowed.

## 13.8 Rollback

| Scenario | Action |
|----------|--------|
| Before destructive change | Supabase Dashboard → Database → Backups (or `pg_dump` via connection string) |
| Failed mid-migration | Restore backup; do not partial-apply without repair script |
| Wrong seed | `DELETE` inactive rows or run idempotent `seed.production.sql` again |
| Revert to legacy | **Not supported** — legacy schema dropped intentionally |

Post-deploy smoke: local `pnpm dlx supabase test db` (must pass before any cloud push).

## Applied cloud migrations (MCP)

| Version | Name |
|---------|------|
| 20260520160311 | cloud_reset_legacy_schema |
| 20260520160336 | init_campus_kitchen_oil_rewards |
| 20260520160359 | disposal_admin_audit_rpc |
| 20260520160402 | add_disposal_capture_coordinates |
| 20260520160407 | scratch_play_rpc |

Future CLI pushes should align repo migration history with cloud (may require `supabase migration repair` if versions differ).
