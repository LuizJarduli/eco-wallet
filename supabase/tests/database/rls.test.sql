begin;

set search_path to public, extensions;

create extension if not exists pgtap with schema extensions;

select plan(6);

insert into auth.users (id, email)
values
  ('10000000-0000-0000-0000-000000000001', 'member@example.test'),
  ('10000000-0000-0000-0000-000000000002', 'other-member@example.test'),
  ('10000000-0000-0000-0000-000000000003', 'admin@example.test');

update public.profiles
set role = 'admin'
where id = '10000000-0000-0000-0000-000000000003';

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);

select lives_ok(
  $$insert into public.disposal_submissions (user_id, drop_off_id, storage_path)
    values (
      '10000000-0000-0000-0000-000000000001',
      (select id from public.drop_off_points where active limit 1),
      '10000000-0000-0000-0000-000000000001/submission.jpg'
    )$$,
  'authenticated member can insert own submitted disposal'
);

select results_eq(
  $$with updated as (
      update public.disposal_submissions
      set status = 'rewarded'
      where user_id = '10000000-0000-0000-0000-000000000001'
      returning 1
    )
    select count(*)::bigint from updated$$,
  $$values (0::bigint)$$,
  'authenticated member cannot update disposal status directly'
);

select lives_ok(
  $$insert into storage.objects (bucket_id, name, owner, metadata)
    values (
      'disposal-photos',
      '10000000-0000-0000-0000-000000000001/submission.jpg',
      '10000000-0000-0000-0000-000000000001',
      '{}'::jsonb
    )$$,
  'authenticated member can upload to own disposal photo prefix'
);

select throws_ok(
  $$insert into storage.objects (bucket_id, name, owner, metadata)
    values (
      'disposal-photos',
      '10000000-0000-0000-0000-000000000002/submission.jpg',
      '10000000-0000-0000-0000-000000000001',
      '{}'::jsonb
    )$$,
  '42501',
  'new row violates row-level security policy for table "objects"',
  'authenticated member cannot upload to another user prefix'
);

reset role;

insert into public.disposal_submissions (user_id, drop_off_id, storage_path)
values (
  '10000000-0000-0000-0000-000000000002',
  (select id from public.drop_off_points where active limit 1),
  '10000000-0000-0000-0000-000000000002/submission.jpg'
);

set local role authenticated;
select set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000003', true);

select results_eq(
  $$select count(*)::bigint from public.disposal_submissions$$,
  $$values (2::bigint)$$,
  'admin role can select all submissions'
);

select results_eq(
  $$with updated as (
      update public.disposal_submissions
      set status = 'rewarded'
      returning 1
    )
    select count(*)::bigint from updated$$,
  $$values (0::bigint)$$,
  'admin role cannot update disposal status through authenticated client policies'
);

select * from finish();

rollback;
