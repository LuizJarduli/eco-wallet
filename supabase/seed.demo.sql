-- Demo / dev mock data (idempotent). Safe to re-run.
-- Members password: demo123456
-- Run: pnpm dlx supabase db execute --file supabase/seed.demo.sql (linked project)
-- Or SQL Editor on cloud.

create extension if not exists pgcrypto with schema extensions;

-- Demo members (profiles + coin_wallets created by triggers)
insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  recovery_sent_at,
  last_sign_in_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'a1000000-0000-4000-8000-000000000001',
    'authenticated',
    'authenticated',
    'maria.demo@ecowallet.test',
    extensions.crypt('demo123456', extensions.gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"display_name":"Maria Demo"}',
    now(),
    now(),
    '',
    '',
    '',
    ''
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'a1000000-0000-4000-8000-000000000002',
    'authenticated',
    'authenticated',
    'joao.demo@ecowallet.test',
    extensions.crypt('demo123456', extensions.gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"display_name":"João Demo"}',
    now(),
    now(),
    '',
    '',
    '',
    ''
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'a1000000-0000-4000-8000-000000000003',
    'authenticated',
    'authenticated',
    'ana.demo@ecowallet.test',
    extensions.crypt('demo123456', extensions.gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}',
    '{"display_name":"Ana Demo"}',
    now(),
    now(),
    '',
    '',
    '',
    ''
  )
on conflict (id) do nothing;

insert into auth.identities (
  id,
  user_id,
  provider_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
select
  gen_random_uuid(),
  u.id,
  u.id::text,
  jsonb_build_object('sub', u.id::text, 'email', u.email),
  'email',
  now(),
  now(),
  now()
from auth.users u
where u.id in (
  'a1000000-0000-4000-8000-000000000001',
  'a1000000-0000-4000-8000-000000000002',
  'a1000000-0000-4000-8000-000000000003'
)
  and not exists (
    select 1
    from auth.identities i
    where i.user_id = u.id and i.provider = 'email'
  );

-- Disposal submissions (admin verification + audit queues)
insert into public.disposal_submissions (
  id,
  user_id,
  drop_off_id,
  storage_path,
  status,
  rejection_reason,
  estimated_liters,
  confidence_status,
  oil_score,
  location_score,
  review_priority,
  capture_latitude,
  capture_longitude,
  submitted_at,
  updated_at
)
select
  v.id,
  v.user_id,
  (select id from public.drop_off_points where active limit 1),
  v.storage_path,
  v.status::public.disposal_status,
  v.rejection_reason::public.rejection_reason_code,
  v.estimated_liters,
  v.confidence_status::public.confidence_status,
  v.oil_score,
  v.location_score,
  v.review_priority,
  v.capture_latitude,
  v.capture_longitude,
  v.submitted_at,
  v.updated_at
from (
  values
    (
      'd1000000-0000-4000-8000-000000000001'::uuid,
      'a1000000-0000-4000-8000-000000000001'::uuid,
      'a1000000-0000-4000-8000-000000000001/demo-1.jpg',
      'submitted',
      null::text,
      null::numeric,
      'pending',
      null::numeric,
      null::numeric,
      'high',
      -23.4767,
      -47.4289,
      now() - interval '2 hours',
      now() - interval '2 hours'
    ),
    (
      'd1000000-0000-4000-8000-000000000002',
      'a1000000-0000-4000-8000-000000000002',
      'a1000000-0000-4000-8000-000000000002/demo-1.jpg',
      'submitted',
      null,
      null,
      'ready',
      0.92,
      0.88,
      'normal',
      -23.4768,
      -47.4290,
      now() - interval '90 minutes',
      now() - interval '90 minutes'
    ),
    (
      'd1000000-0000-4000-8000-000000000003',
      'a1000000-0000-4000-8000-000000000003',
      'a1000000-0000-4000-8000-000000000003/demo-1.jpg',
      'submitted',
      null,
      null,
      'ready',
      0.81,
      0.79,
      'normal',
      -23.4769,
      -47.4291,
      now() - interval '1 hour',
      now() - interval '1 hour'
    ),
    (
      'd1000000-0000-4000-8000-000000000004',
      'a1000000-0000-4000-8000-000000000001',
      'a1000000-0000-4000-8000-000000000001/demo-2.jpg',
      'submitted',
      null,
      null,
      'failed',
      0.41,
      0.55,
      'low',
      -23.4770,
      -47.4292,
      now() - interval '30 minutes',
      now() - interval '30 minutes'
    ),
    (
      'd1000000-0000-4000-8000-000000000005',
      'a1000000-0000-4000-8000-000000000002',
      'a1000000-0000-4000-8000-000000000002/demo-2.jpg',
      'under_review',
      null,
      null,
      'ready',
      0.95,
      0.91,
      'high',
      -23.4771,
      -47.4293,
      now() - interval '3 hours',
      now() - interval '20 minutes'
    ),
    (
      'd1000000-0000-4000-8000-000000000006',
      'a1000000-0000-4000-8000-000000000003',
      'a1000000-0000-4000-8000-000000000003/demo-2.jpg',
      'awaiting_audit',
      null,
      1.50,
      'ready',
      0.89,
      0.86,
      'normal',
      -23.4772,
      -47.4294,
      now() - interval '1 day',
      now() - interval '4 hours'
    ),
    (
      'd1000000-0000-4000-8000-000000000007',
      'a1000000-0000-4000-8000-000000000001',
      'a1000000-0000-4000-8000-000000000001/demo-3.jpg',
      'awaiting_audit',
      null,
      2.00,
      'ready',
      0.93,
      0.90,
      'high',
      -23.4773,
      -47.4295,
      now() - interval '2 days',
      now() - interval '6 hours'
    ),
    (
      'd1000000-0000-4000-8000-000000000008',
      'a1000000-0000-4000-8000-000000000002',
      'a1000000-0000-4000-8000-000000000002/demo-3.jpg',
      'rejected',
      'unclear_photo',
      null,
      'ready',
      0.62,
      0.71,
      'normal',
      -23.4774,
      -47.4296,
      now() - interval '3 days',
      now() - interval '2 days'
    )
) as v(
  id,
  user_id,
  storage_path,
  status,
  rejection_reason,
  estimated_liters,
  confidence_status,
  oil_score,
  location_score,
  review_priority,
  capture_latitude,
  capture_longitude,
  submitted_at,
  updated_at
)
on conflict (id) do nothing;
