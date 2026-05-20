-- Cloud post-deploy smoke checks (run in SQL editor or: supabase db execute --file ...)
-- Expect all rows to show ok = true.

select 'schema_disposal_status' as check_name,
       (
         select string_agg(enumlabel::text, ',' order by enumsortorder)
         from pg_enum
         join pg_type on pg_type.oid = enumtypid
         where typname = 'disposal_status'
       ) = 'submitted,under_review,approved,awaiting_audit,rewarded,rejected' as ok;

select 'seed_reward_rule' as check_name,
       exists (
         select 1 from public.reward_rules
         where active and coins_per_liter = 10 and min_liters = 1.00
       ) as ok;

select 'seed_drop_off' as check_name,
       exists (select 1 from public.drop_off_points where active) as ok;

select 'seed_scratch_campaign' as check_name,
       exists (select 1 from public.scratch_card_campaigns where active) as ok;

select 'storage_bucket' as check_name,
       exists (select 1 from storage.buckets where id = 'disposal-photos' and not public) as ok;

select 'rls_no_member_update_disposals' as check_name,
       not exists (
         select 1 from pg_policies
         where schemaname = 'public'
           and tablename = 'disposal_submissions'
           and cmd in ('UPDATE', 'ALL')
       ) as ok;

select 'storage_user_prefix_insert' as check_name,
       exists (
         select 1 from pg_policies
         where schemaname = 'storage'
           and tablename = 'objects'
           and policyname = 'Members can upload disposal photos under own prefix'
           and cmd = 'INSERT'
       ) as ok;

select 'admin_rpc_service_role_only' as check_name,
       (
         select count(*) = 3
         from pg_proc p
         join pg_namespace n on n.oid = p.pronamespace
         where n.nspname = 'public'
           and p.proname in (
             'approve_disposal_admin',
             'audit_disposal_collection_admin',
             'play_scratch_card_member'
           )
       ) as ok;
