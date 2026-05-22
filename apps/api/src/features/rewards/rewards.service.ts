import { AppError } from "../../core/errors/app-error.js";
import {
  parseScratchProbabilities,
  pickWeightedOutcome,
  type RawScratchProbabilities,
  type ScratchOutcomeConfig,
  type ScratchProbabilities
} from "./scratch-outcome.js";

export interface ScratchCardCampaign {
  id: string;
  name: string;
  costCoins: number;
  active: boolean;
  probabilities: ScratchProbabilities;
}

export interface MemberWallet {
  userId: string;
  availableBalance: number;
}

export interface ScratchPlayResult {
  playId: string;
  campaignId: string;
  outcomeKey: string;
  discountPercent: number;
  rarity: string;
  costCoins: number;
  availableBalance: number;
}

export interface ScratchPlayRecord {
  id: string;
  userId: string;
  campaignId: string;
  outcome: string;
}

export interface RewardsRepository {
  findCampaign(campaignId: string): Promise<ScratchCardCampaign | null>;
  getWallet(userId: string): Promise<MemberWallet>;
  persistScratchPlay(input: {
    userId: string;
    campaignId: string;
    outcomeKey: string;
  }): Promise<{ playId: string; availableBalance: number }>;
  findScratchPlay(playId: string): Promise<ScratchPlayRecord | null>;
}

export interface ScratchRewardsService {
  playScratch(userId: string, campaignId: string): Promise<ScratchPlayResult>;
}

export type RandomFn = () => number;

const assertActiveCampaign = (
  campaign: ScratchCardCampaign | null,
  campaignId: string
): ScratchCardCampaign => {
  if (!campaign || !campaign.active) {
    throw new AppError(
      "CAMPAIGN_INACTIVE",
      409,
      `Scratch campaign ${campaignId} is not active.`
    );
  }

  return campaign;
};

const assertSufficientBalance = (
  wallet: MemberWallet,
  costCoins: number
): void => {
  if (wallet.availableBalance < costCoins) {
    throw new AppError(
      "INSUFFICIENT_BALANCE",
      422,
      "Available coin balance is insufficient for this scratch play."
    );
  }
};

const toPlayResult = (
  campaign: ScratchCardCampaign,
  outcomeKey: string,
  outcomeConfig: ScratchOutcomeConfig,
  persistence: { playId: string; availableBalance: number }
): ScratchPlayResult => ({
  availableBalance: persistence.availableBalance,
  campaignId: campaign.id,
  costCoins: campaign.costCoins,
  discountPercent: outcomeConfig.discountPercent,
  outcomeKey,
  playId: persistence.playId,
  rarity: outcomeConfig.rarity
});

export const createScratchRewardsService = (
  repository: RewardsRepository,
  random: RandomFn = Math.random
): ScratchRewardsService => ({
  async playScratch(userId, campaignId) {
    const campaign = assertActiveCampaign(
      await repository.findCampaign(campaignId),
      campaignId
    );
    const wallet = await repository.getWallet(userId);

    assertSufficientBalance(wallet, campaign.costCoins);

    const { config, outcomeKey } = pickWeightedOutcome(
      campaign.probabilities,
      random
    );

    const persistence = await repository.persistScratchPlay({
      campaignId,
      outcomeKey,
      userId
    });

    return toPlayResult(campaign, outcomeKey, config, persistence);
  }
});

export interface ScratchCardCampaignRow {
  id: string;
  name: string;
  cost_coins: number;
  active: boolean;
  probabilities: RawScratchProbabilities;
}

export const toScratchCardCampaign = (
  row: ScratchCardCampaignRow
): ScratchCardCampaign => ({
  active: row.active,
  costCoins: row.cost_coins,
  id: row.id,
  name: row.name,
  probabilities: parseScratchProbabilities(row.probabilities)
});
