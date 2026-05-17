insert into public.reward_rules (coins_per_liter, min_liters, effective_from, active)
values (10, 1.00, now(), true)
on conflict do nothing;

insert into public.drop_off_points (name, campus, address, latitude, longitude, active)
values (
  'UniFacens Main Kitchen Oil Drop-Off',
  'UniFacens',
  'Rodovia Senador José Ermírio de Moraes, 1425, Sorocaba, SP',
  -23.476700,
  -47.428900,
  true
)
on conflict do nothing;

insert into public.scratch_card_campaigns (name, cost_coins, probabilities, active)
values (
  'UniFacens Monthly Installment Discount',
  10,
  '{
    "common_discount_5": {
      "discount_percent": 5,
      "rarity": "common",
      "weight": 90
    },
    "rare_discount_10": {
      "discount_percent": 10,
      "rarity": "rare",
      "weight": 10
    }
  }'::jsonb,
  true
)
on conflict do nothing;
