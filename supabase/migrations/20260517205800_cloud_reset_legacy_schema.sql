-- One-time cloud reset: drops pre-PRD prototype tables (zero production rows as of deploy).
-- Safe only when cloud public data is disposable. See supabase/docs/cloud-deployment-plan.md.

drop table if exists public.wallet_transactions cascade;
drop table if exists public.disposals cascade;
drop table if exists public.collection_batches cascade;
drop table if exists public.withdrawal_requests cascade;
drop table if exists public.wallets cascade;
drop table if exists public.collection_points cascade;
drop table if exists public.users cascade;

drop type if exists public.disposal_status cascade;
drop type if exists public.transaction_type cascade;
drop type if exists public.user_role cascade;
drop type if exists public.withdrawal_status cascade;
