begin;

set search_path to public, extensions;

create extension if not exists pgtap with schema extensions;

select plan(3);

select results_eq(
  $$select coins_per_liter, min_liters from public.reward_rules where active order by effective_from desc limit 1$$,
  $$values (10, 1.00::numeric)$$,
  'seeded active reward rule returns 10 coins per liter and 1 liter minimum'
);

select results_eq(
  $$select count(*)::bigint from public.drop_off_points where active$$,
  $$values (1::bigint)$$,
  'at least one active drop-off point is seeded'
);

select results_eq(
  $$select
      (probabilities #>> '{common_discount_5,discount_percent}')::int,
      probabilities #>> '{common_discount_5,rarity}',
      (probabilities #>> '{rare_discount_10,discount_percent}')::int,
      probabilities #>> '{rare_discount_10,rarity}'
    from public.scratch_card_campaigns
    where active
    order by created_at
    limit 1$$,
  $$values (5, 'common', 10, 'rare')$$,
  'seeded scratch card campaign includes 5 percent common and 10 percent rare outcomes'
);

select * from finish();

rollback;
