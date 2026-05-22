import { AppError } from "../../core/errors/app-error.js";
import {
  createSupabaseServiceClient,
  type SupabaseServiceClient
} from "../../core/supabase/service-client.js";
import {
  toScratchCardCampaign,
  type RewardsRepository,
  type ScratchCardCampaign,
  type ScratchCardCampaignRow,
  type ScratchPlayRecord
} from "./rewards.service.js";

interface SupabaseErrorLike {
  message: string;
}

interface PlayScratchRpcRow {
  play_id: string;
  available_balance: number;
}

interface WalletRow {
  user_id: string;
  available_balance: number;
}

interface ScratchPlayRow {
  id: string;
  user_id: string;
  campaign_id: string;
  outcome: string;
}

const throwIfDomainRpcError = (error: SupabaseErrorLike): never => {
  if (error.message.includes("INSUFFICIENT_BALANCE")) {
    throw new AppError(
      "INSUFFICIENT_BALANCE",
      422,
      "Available coin balance is insufficient for this scratch play."
    );
  }

  if (error.message.includes("CAMPAIGN_INACTIVE")) {
    throw new AppError(
      "CAMPAIGN_INACTIVE",
      409,
      "Scratch campaign is not active."
    );
  }

  if (error.message.includes("VALIDATION_ERROR")) {
    throw new AppError("VALIDATION_ERROR", 400, "Scratch play request is invalid.");
  }

  throw new AppError(
    "INTERNAL_ERROR",
    500,
    "Scratch rewards persistence operation failed."
  );
};

export class SupabaseRewardsRepository implements RewardsRepository {
  constructor(
    private readonly client: SupabaseServiceClient = createSupabaseServiceClient()
  ) {}

  async findCampaign(campaignId: string): Promise<ScratchCardCampaign | null> {
    const { data, error } = await this.client
      .from("scratch_card_campaigns")
      .select("id,name,cost_coins,active,probabilities")
      .eq("id", campaignId)
      .maybeSingle<ScratchCardCampaignRow>();

    if (error) {
      throwIfDomainRpcError(error);
    }

    return data ? toScratchCardCampaign(data) : null;
  }

  async getWallet(userId: string): Promise<{ userId: string; availableBalance: number }> {
    const { data, error } = await this.client
      .from("coin_wallets")
      .select("user_id,available_balance")
      .eq("user_id", userId)
      .maybeSingle<WalletRow>();

    if (error) {
      throwIfDomainRpcError(error);
    }

    return {
      availableBalance: data?.available_balance ?? 0,
      userId
    };
  }

  async persistScratchPlay(input: {
    userId: string;
    campaignId: string;
    outcomeKey: string;
  }): Promise<{ playId: string; availableBalance: number }> {
    const { data, error } = await this.client
      .rpc("play_scratch_card_member", {
        p_campaign_id: input.campaignId,
        p_outcome: input.outcomeKey,
        p_user_id: input.userId
      })
      .single<PlayScratchRpcRow>();

    if (error) {
      throwIfDomainRpcError(error);
    }

    if (!data) {
      throw new AppError(
        "INTERNAL_ERROR",
        500,
        "Scratch play operation did not return a result."
      );
    }

    return {
      availableBalance: data.available_balance,
      playId: data.play_id
    };
  }

  async findScratchPlay(playId: string): Promise<ScratchPlayRecord | null> {
    const { data, error } = await this.client
      .from("scratch_card_plays")
      .select("id,user_id,campaign_id,outcome")
      .eq("id", playId)
      .maybeSingle<ScratchPlayRow>();

    if (error) {
      throwIfDomainRpcError(error);
    }

    if (!data) {
      return null;
    }

    return {
      campaignId: data.campaign_id,
      id: data.id,
      outcome: data.outcome,
      userId: data.user_id
    };
  }
}
