-- Fix ambiguous available_balance in RETURNING (conflicts with RETURNS TABLE column).
create or replace function public.play_scratch_card_member(
  p_user_id uuid,
  p_campaign_id uuid,
  p_outcome text
)
returns table (
  play_id uuid,
  available_balance integer
)
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_campaign public.scratch_card_campaigns%rowtype;
  v_wallet public.coin_wallets%rowtype;
  v_play_id uuid;
  v_available_balance integer;
begin
  if p_user_id is null or p_campaign_id is null or p_outcome is null then
    raise exception 'VALIDATION_ERROR' using errcode = 'P0001';
  end if;

  select *
  into v_campaign
  from public.scratch_card_campaigns
  where id = p_campaign_id
  for update;

  if not found or not v_campaign.active then
    raise exception 'CAMPAIGN_INACTIVE' using errcode = 'P0001';
  end if;

  if not (v_campaign.probabilities ? p_outcome) then
    raise exception 'VALIDATION_ERROR' using errcode = 'P0001';
  end if;

  select *
  into v_wallet
  from public.coin_wallets
  where user_id = p_user_id
  for update;

  if not found then
    insert into public.coin_wallets (user_id, pending_balance, available_balance)
    values (p_user_id, 0, 0)
    returning * into v_wallet;
  end if;

  if v_wallet.available_balance < v_campaign.cost_coins then
    raise exception 'INSUFFICIENT_BALANCE' using errcode = 'P0001';
  end if;

  insert into public.scratch_card_plays (user_id, campaign_id, outcome)
  values (p_user_id, p_campaign_id, p_outcome)
  returning id into v_play_id;

  insert into public.coin_ledger (wallet_user_id, amount, type, reference_id)
  values (p_user_id, v_campaign.cost_coins, 'spent', v_play_id);

  update public.coin_wallets
  set available_balance = coin_wallets.available_balance - v_campaign.cost_coins,
      updated_at = now()
  where user_id = p_user_id
  returning coin_wallets.available_balance into v_available_balance;

  return query
  select v_play_id, v_available_balance;
end;
$$;
