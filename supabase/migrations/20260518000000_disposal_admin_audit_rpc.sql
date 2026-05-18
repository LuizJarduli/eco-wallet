create or replace function public.approve_disposal_admin(
  p_submission_id uuid,
  p_admin_id uuid,
  p_estimated_liters numeric
)
returns table (pending_coins integer)
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_submission public.disposal_submissions%rowtype;
  v_rule public.reward_rules%rowtype;
  v_pending_coins integer;
begin
  if p_admin_id is null then
    raise exception 'INVALID_TRANSITION' using errcode = 'P0001';
  end if;

  select *
  into v_submission
  from public.disposal_submissions
  where id = p_submission_id
  for update;

  if not found then
    raise exception 'DISPOSAL_NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_submission.status <> 'submitted' then
    raise exception 'INVALID_TRANSITION' using errcode = 'P0001';
  end if;

  select *
  into v_rule
  from public.reward_rules
  where active
  order by effective_from desc
  limit 1;

  if not found then
    raise exception 'ACTIVE_REWARD_RULE_NOT_FOUND' using errcode = 'P0001';
  end if;

  v_pending_coins := floor(p_estimated_liters)::integer * v_rule.coins_per_liter;

  update public.disposal_submissions
  set status = 'awaiting_audit',
      estimated_liters = p_estimated_liters
  where id = p_submission_id;

  insert into public.coin_wallets (user_id, pending_balance, available_balance)
  values (v_submission.user_id, v_pending_coins, 0)
  on conflict (user_id) do update
  set pending_balance = public.coin_wallets.pending_balance + excluded.pending_balance,
      updated_at = now();

  if v_pending_coins > 0 then
    insert into public.coin_ledger (wallet_user_id, amount, type, reference_id)
    values (v_submission.user_id, v_pending_coins, 'pending', p_submission_id);
  end if;

  return query select v_pending_coins;
end;
$$;

revoke execute on function public.approve_disposal_admin(uuid, uuid, numeric) from public;
revoke execute on function public.approve_disposal_admin(uuid, uuid, numeric) from anon;
revoke execute on function public.approve_disposal_admin(uuid, uuid, numeric) from authenticated;
grant execute on function public.approve_disposal_admin(uuid, uuid, numeric) to service_role;

create or replace function public.audit_disposal_collection_admin(
  p_submission_id uuid,
  p_admin_id uuid,
  p_audited_liters numeric
)
returns table (coins_released integer)
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_submission public.disposal_submissions%rowtype;
  v_rule public.reward_rules%rowtype;
  v_pending_for_submission integer;
  v_coins_released integer;
begin
  select *
  into v_submission
  from public.disposal_submissions
  where id = p_submission_id
  for update;

  if not found then
    raise exception 'DISPOSAL_NOT_FOUND' using errcode = 'P0001';
  end if;

  if v_submission.status <> 'awaiting_audit' then
    raise exception 'INVALID_TRANSITION' using errcode = 'P0001';
  end if;

  select *
  into v_rule
  from public.reward_rules
  where active
  order by effective_from desc
  limit 1;

  if not found then
    raise exception 'ACTIVE_REWARD_RULE_NOT_FOUND' using errcode = 'P0001';
  end if;

  if p_audited_liters < v_rule.min_liters then
    raise exception 'BELOW_MIN_VOLUME' using errcode = 'P0001';
  end if;

  v_coins_released := floor(p_audited_liters)::integer * v_rule.coins_per_liter;

  select coalesce(sum(amount), 0)::integer
  into v_pending_for_submission
  from public.coin_ledger
  where wallet_user_id = v_submission.user_id
    and reference_id = p_submission_id
    and type = 'pending';

  insert into public.collection_audits (submission_id, admin_id, audited_liters)
  values (p_submission_id, p_admin_id, p_audited_liters);

  insert into public.inventory_ledger (delta_liters, source_submission_id)
  values (p_audited_liters, p_submission_id);

  insert into public.coin_wallets (user_id, pending_balance, available_balance)
  values (v_submission.user_id, 0, v_coins_released)
  on conflict (user_id) do update
  set pending_balance = greatest(
        public.coin_wallets.pending_balance - v_pending_for_submission,
        0
      ),
      available_balance = public.coin_wallets.available_balance + excluded.available_balance,
      updated_at = now();

  if v_coins_released > 0 then
    insert into public.coin_ledger (wallet_user_id, amount, type, reference_id)
    values (v_submission.user_id, v_coins_released, 'available', p_submission_id);
  end if;

  update public.disposal_submissions
  set status = 'rewarded'
  where id = p_submission_id;

  return query select v_coins_released;
end;
$$;

revoke execute on function public.audit_disposal_collection_admin(uuid, uuid, numeric) from public;
revoke execute on function public.audit_disposal_collection_admin(uuid, uuid, numeric) from anon;
revoke execute on function public.audit_disposal_collection_admin(uuid, uuid, numeric) from authenticated;
grant execute on function public.audit_disposal_collection_admin(uuid, uuid, numeric) to service_role;
