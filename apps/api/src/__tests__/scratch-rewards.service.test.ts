import request from "supertest";
import { beforeEach, describe, expect, it } from "vitest";

import { createApp } from "../core/http/app.js";
import type {
  MemberWallet,
  RewardsRepository,
  ScratchCardCampaign,
  ScratchPlayRecord
} from "../features/rewards/rewards.service.js";
import { createScratchRewardsService } from "../features/rewards/rewards.service.js";
import { createJwtVerifier, createRoleLookup } from "../test/fakes.js";

const campaignId = "3f767c9d-f95f-49f3-8945-57b74d9a2f75";

const activeCampaign: ScratchCardCampaign = {
  active: true,
  costCoins: 10,
  id: campaignId,
  name: "UniFacens Monthly Installment Discount",
  probabilities: {
    common_discount_5: {
      discountPercent: 5,
      rarity: "common",
      weight: 90
    },
    rare_discount_10: {
      discountPercent: 10,
      rarity: "rare",
      weight: 10
    }
  }
};

const inactiveCampaign: ScratchCardCampaign = {
  ...activeCampaign,
  active: false
};

interface SpentLedgerEntry {
  walletUserId: string;
  amount: number;
  type: "spent";
  referenceId: string;
}

class InMemoryRewardsRepository implements RewardsRepository {
  readonly spentLedger: SpentLedgerEntry[] = [];

  readonly plays: ScratchPlayRecord[] = [];

  constructor(
    private campaign: ScratchCardCampaign | null = activeCampaign,
    private readonly wallets = new Map<string, MemberWallet>()
  ) {}

  async findCampaign(campaignId: string): Promise<ScratchCardCampaign | null> {
    if (!this.campaign || this.campaign.id !== campaignId) {
      return null;
    }

    return this.campaign;
  }

  async getWallet(userId: string): Promise<MemberWallet> {
    return (
      this.wallets.get(userId) ?? {
        availableBalance: 0,
        userId
      }
    );
  }

  async persistScratchPlay(input: {
    userId: string;
    campaignId: string;
    outcomeKey: string;
  }): Promise<{ playId: string; availableBalance: number }> {
    const campaign = await this.findCampaign(input.campaignId);

    if (!campaign?.active) {
      throw new Error("CAMPAIGN_INACTIVE");
    }

    const wallet = await this.getWallet(input.userId);

    if (wallet.availableBalance < campaign.costCoins) {
      throw new Error("INSUFFICIENT_BALANCE");
    }

    const playId = `play-${this.plays.length + 1}`;
    const availableBalance = wallet.availableBalance - campaign.costCoins;

    this.wallets.set(input.userId, {
      availableBalance,
      userId: input.userId
    });

    this.plays.push({
      campaignId: input.campaignId,
      id: playId,
      outcome: input.outcomeKey,
      userId: input.userId
    });

    this.spentLedger.push({
      amount: campaign.costCoins,
      referenceId: playId,
      type: "spent",
      walletUserId: input.userId
    });

    return { availableBalance, playId };
  }

  async findScratchPlay(playId: string): Promise<ScratchPlayRecord | null> {
    return this.plays.find((play) => play.id === playId) ?? null;
  }

  setCampaign(campaign: ScratchCardCampaign | null): void {
    this.campaign = campaign;
  }

  setWallet(userId: string, availableBalance: number): void {
    this.wallets.set(userId, { availableBalance, userId });
  }
}

const createTestApp = (repository: InMemoryRewardsRepository) =>
  createApp({
    jwtVerifier: createJwtVerifier("member-1"),
    profileRoleLookup: createRoleLookup("member"),
    rewardsRepository: repository,
    scratchRewardsService: createScratchRewardsService(
      repository,
      () => 0
    )
  });

describe("scratch rewards service", () => {
  let repository: InMemoryRewardsRepository;

  beforeEach(() => {
    repository = new InMemoryRewardsRepository();
  });

  it("returns INSUFFICIENT_BALANCE when available coins are zero", async () => {
    const response = await request(createTestApp(repository))
      .post("/v1/rewards/scratch/play")
      .set("Authorization", "Bearer valid-token")
      .send({ campaignId })
      .expect(422);

    expect(response.body.error.code).toBe("INSUFFICIENT_BALANCE");
    expect(repository.plays).toHaveLength(0);
    expect(repository.spentLedger).toHaveLength(0);
  });

  it("deducts cost_coins exactly once on a successful play", async () => {
    repository.setWallet("member-1", 25);

    const response = await request(createTestApp(repository))
      .post("/v1/rewards/scratch/play")
      .set("Authorization", "Bearer valid-token")
      .send({ campaignId })
      .expect(201);

    expect(response.body.data).toMatchObject({
      availableBalance: 15,
      campaignId,
      costCoins: 10,
      discountPercent: 5,
      outcomeKey: "common_discount_5",
      rarity: "common"
    });
    expect(repository.spentLedger).toHaveLength(1);
    expect(repository.spentLedger[0]).toMatchObject({
      amount: 10,
      type: "spent",
      walletUserId: "member-1"
    });
    expect(repository.spentLedger[0].referenceId).toBe(response.body.data.playId);
  });

  it("returns CAMPAIGN_INACTIVE for inactive campaigns", async () => {
    repository.setCampaign(inactiveCampaign);
    repository.setWallet("member-1", 50);

    const response = await request(createTestApp(repository))
      .post("/v1/rewards/scratch/play")
      .set("Authorization", "Bearer valid-token")
      .send({ campaignId })
      .expect(409);

    expect(response.body.error.code).toBe("CAMPAIGN_INACTIVE");
    expect(repository.plays).toHaveLength(0);
  });

  it("returns VALIDATION_ERROR for invalid play bodies", async () => {
    const response = await request(createTestApp(repository))
      .post("/v1/rewards/scratch/play")
      .set("Authorization", "Bearer valid-token")
      .send({})
      .expect(400);

    expect(response.body.error.code).toBe("VALIDATION_ERROR");
  });

  it("persists scratch_card_plays linked to user and campaign", async () => {
    repository.setWallet("member-1", 30);

    const response = await request(createTestApp(repository))
      .post("/v1/rewards/scratch/play")
      .set("Authorization", "Bearer valid-token")
      .send({ campaignId })
      .expect(201);

    const play = await repository.findScratchPlay(response.body.data.playId);

    expect(play).toMatchObject({
      campaignId,
      outcome: "common_discount_5",
      userId: "member-1"
    });
  });
});
