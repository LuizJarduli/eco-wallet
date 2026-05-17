begin;

set search_path to public, extensions;

create extension if not exists pgtap with schema extensions;

select plan(14);

select has_table('public', 'profiles', 'profiles table exists');
select has_table('public', 'drop_off_points', 'drop_off_points table exists');
select has_table('public', 'reward_rules', 'reward_rules table exists');
select has_table('public', 'disposal_submissions', 'disposal_submissions table exists');
select has_table('public', 'collection_audits', 'collection_audits table exists');
select has_table('public', 'inventory_ledger', 'inventory_ledger table exists');
select has_table('public', 'coin_wallets', 'coin_wallets table exists');
select has_table('public', 'coin_ledger', 'coin_ledger table exists');
select has_table('public', 'scratch_card_campaigns', 'scratch_card_campaigns table exists');
select has_table('public', 'device_tokens', 'device_tokens table exists');

select is(
  (select string_agg(enumlabel::text, ',' order by enumsortorder) from pg_enum join pg_type on pg_type.oid = enumtypid where typname = 'disposal_status'),
  'submitted,under_review,approved,awaiting_audit,rewarded,rejected',
  'disposal_status values match TechSpec'
);

select is(
  (select string_agg(enumlabel::text, ',' order by enumsortorder) from pg_enum join pg_type on pg_type.oid = enumtypid where typname = 'confidence_status'),
  'pending,ready,failed',
  'confidence_status values match TechSpec'
);

select is(
  (select string_agg(enumlabel::text, ',' order by enumsortorder) from pg_enum join pg_type on pg_type.oid = enumtypid where typname = 'coin_entry_type'),
  'pending,available,spent',
  'coin_entry_type values match TechSpec'
);

select is(
  (select string_agg(enumlabel::text, ',' order by enumsortorder) from pg_enum join pg_type on pg_type.oid = enumtypid where typname = 'rejection_reason_code'),
  'not_oil,unclear_photo,bottle_not_visible,below_min_volume,invalid_drop_off,duplicate,other',
  'rejection_reason_code values match PRD'
);

select * from finish();

rollback;
