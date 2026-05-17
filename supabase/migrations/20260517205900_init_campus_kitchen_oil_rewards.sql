create schema if not exists app_private;

create type public.disposal_status as enum (
  'submitted',
  'under_review',
  'approved',
  'awaiting_audit',
  'rewarded',
  'rejected'
);

create type public.confidence_status as enum (
  'pending',
  'ready',
  'failed'
);

create type public.coin_entry_type as enum (
  'pending',
  'available',
  'spent'
);

create type public.rejection_reason_code as enum (
  'not_oil',
  'unclear_photo',
  'bottle_not_visible',
  'below_min_volume',
  'invalid_drop_off',
  'duplicate',
  'other'
);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('member', 'admin')),
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.drop_off_points (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  campus text not null,
  address text,
  latitude numeric(9, 6) not null,
  longitude numeric(9, 6) not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.reward_rules (
  id uuid primary key default gen_random_uuid(),
  coins_per_liter integer not null check (coins_per_liter > 0),
  min_liters numeric(8, 2) not null check (min_liters > 0),
  effective_from timestamptz not null default now(),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.disposal_submissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  drop_off_id uuid not null references public.drop_off_points (id),
  storage_path text not null,
  status public.disposal_status not null default 'submitted',
  rejection_reason public.rejection_reason_code,
  estimated_liters numeric(8, 2) check (estimated_liters is null or estimated_liters > 0),
  confidence_status public.confidence_status not null default 'pending',
  oil_score numeric(4, 3) check (oil_score is null or oil_score between 0 and 1),
  location_score numeric(4, 3) check (location_score is null or location_score between 0 and 1),
  review_priority text not null default 'normal' check (review_priority in ('low', 'normal', 'high')),
  confidence_provider text,
  confidence_raw jsonb,
  submitted_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint rejected_submissions_have_reason
    check (status <> 'rejected' or rejection_reason is not null),
  constraint non_rejected_submissions_do_not_have_reason
    check (status = 'rejected' or rejection_reason is null)
);

create table public.collection_audits (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null unique references public.disposal_submissions (id) on delete cascade,
  admin_id uuid not null references public.profiles (id),
  audited_liters numeric(8, 2) not null check (audited_liters > 0),
  audited_at timestamptz not null default now()
);

create table public.inventory_ledger (
  id uuid primary key default gen_random_uuid(),
  delta_liters numeric(8, 2) not null check (delta_liters <> 0),
  source_submission_id uuid unique references public.disposal_submissions (id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.coin_wallets (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  pending_balance integer not null default 0 check (pending_balance >= 0),
  available_balance integer not null default 0 check (available_balance >= 0),
  updated_at timestamptz not null default now()
);

create table public.coin_ledger (
  id uuid primary key default gen_random_uuid(),
  wallet_user_id uuid not null references public.coin_wallets (user_id) on delete cascade,
  amount integer not null check (amount > 0),
  type public.coin_entry_type not null,
  reference_id uuid,
  created_at timestamptz not null default now()
);

create table public.scratch_card_campaigns (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  cost_coins integer not null default 0 check (cost_coins >= 0),
  probabilities jsonb not null check (jsonb_typeof(probabilities) = 'object'),
  active boolean not null default true,
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint scratch_card_campaign_dates_ordered
    check (ends_at is null or ends_at > starts_at)
);

create table public.scratch_card_plays (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  campaign_id uuid not null references public.scratch_card_campaigns (id),
  outcome text not null,
  created_at timestamptz not null default now()
);

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  platform text not null check (platform in ('android', 'ios', 'web')),
  token text not null,
  created_at timestamptz not null default now(),
  unique (user_id, token)
);

create index disposal_submissions_user_id_idx on public.disposal_submissions (user_id);
create index disposal_submissions_status_idx on public.disposal_submissions (status);
create index disposal_submissions_drop_off_id_idx on public.disposal_submissions (drop_off_id);
create index collection_audits_admin_id_idx on public.collection_audits (admin_id);
create index coin_ledger_wallet_user_id_idx on public.coin_ledger (wallet_user_id);
create index scratch_card_plays_user_id_idx on public.scratch_card_plays (user_id);
create index device_tokens_user_id_idx on public.device_tokens (user_id);

create or replace function app_private.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function app_private.set_updated_at();

create trigger drop_off_points_set_updated_at
before update on public.drop_off_points
for each row execute function app_private.set_updated_at();

create trigger reward_rules_set_updated_at
before update on public.reward_rules
for each row execute function app_private.set_updated_at();

create trigger disposal_submissions_set_updated_at
before update on public.disposal_submissions
for each row execute function app_private.set_updated_at();

create trigger scratch_card_campaigns_set_updated_at
before update on public.scratch_card_campaigns
for each row execute function app_private.set_updated_at();

create or replace function app_private.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select role from public.profiles where id = (select auth.uid())
$$;

create or replace function app_private.create_wallet_for_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.coin_wallets (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create trigger profiles_create_wallet
after insert on public.profiles
for each row execute function app_private.create_wallet_for_profile();

create or replace function app_private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'display_name', new.email))
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created_create_profile
after insert on auth.users
for each row execute function app_private.handle_new_auth_user();

create or replace function app_private.enforce_rewarded_submission_has_audit()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.status = 'rewarded'
    and not exists (
      select 1
      from public.collection_audits
      where submission_id = new.id
    )
  then
    raise exception 'rewarded status requires a collection audit'
      using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger disposal_submissions_require_audit_before_rewarded
before insert or update of status on public.disposal_submissions
for each row execute function app_private.enforce_rewarded_submission_has_audit();

alter table public.profiles enable row level security;
alter table public.drop_off_points enable row level security;
alter table public.reward_rules enable row level security;
alter table public.disposal_submissions enable row level security;
alter table public.collection_audits enable row level security;
alter table public.inventory_ledger enable row level security;
alter table public.coin_wallets enable row level security;
alter table public.coin_ledger enable row level security;
alter table public.scratch_card_campaigns enable row level security;
alter table public.scratch_card_plays enable row level security;
alter table public.device_tokens enable row level security;

grant usage on schema public to anon, authenticated;
grant usage on schema app_private to authenticated;
grant execute on function app_private.current_user_role() to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on public.drop_off_points to anon;
grant select on public.scratch_card_campaigns to anon;

create policy "Members can read own profile and admins can read profiles"
on public.profiles
for select
to authenticated
using (id = (select auth.uid()) or app_private.current_user_role() = 'admin');

create policy "Authenticated users can read active drop off points"
on public.drop_off_points
for select
to authenticated
using (active or app_private.current_user_role() = 'admin');

create policy "Anonymous users can read active drop off points"
on public.drop_off_points
for select
to anon
using (active);

create policy "Authenticated users can read active reward rules"
on public.reward_rules
for select
to authenticated
using (active or app_private.current_user_role() = 'admin');

create policy "Members can insert own submitted disposal"
on public.disposal_submissions
for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and status = 'submitted'
  and confidence_status = 'pending'
  and rejection_reason is null
);

create policy "Members read own submissions and admins read all submissions"
on public.disposal_submissions
for select
to authenticated
using (user_id = (select auth.uid()) or app_private.current_user_role() = 'admin');

create policy "Admins can read collection audits"
on public.collection_audits
for select
to authenticated
using (app_private.current_user_role() = 'admin');

create policy "Members can read own wallet"
on public.coin_wallets
for select
to authenticated
using (user_id = (select auth.uid()));

create policy "Members can read own coin ledger"
on public.coin_ledger
for select
to authenticated
using (wallet_user_id = (select auth.uid()));

create policy "Authenticated users can read active scratch card campaigns"
on public.scratch_card_campaigns
for select
to authenticated
using (active or app_private.current_user_role() = 'admin');

create policy "Anonymous users can read active scratch card campaigns"
on public.scratch_card_campaigns
for select
to anon
using (active);

create policy "Members can read own scratch card plays"
on public.scratch_card_plays
for select
to authenticated
using (user_id = (select auth.uid()));

create policy "Members can manage own device tokens"
on public.device_tokens
for all
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'disposal-photos',
  'disposal-photos',
  false,
  10485760,
  array['image/png', 'image/jpeg', 'image/webp']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy "Members can read own disposal photos"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'disposal-photos'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "Members can upload disposal photos under own prefix"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'disposal-photos'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
