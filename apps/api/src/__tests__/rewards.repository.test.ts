import { describe, expect, it } from "vitest";

import { AppError } from "../core/errors/app-error.js";
import { SupabaseRewardsRepository } from "../features/rewards/rewards.repository.js";

const campaignRow = {
  active: true,
  cost_coins: 10,
  id: "3f767c9d-f95f-49f3-8945-57b74d9a2f75",
  name: "Campaign",
  probabilities: {
    common_discount_5: {
      discount_percent: 5,
      rarity: "common",
      weight: 90
    },
    rare_discount_10: {
      discount_percent: 10,
      rarity: "rare",
      weight: 10
    }
  }
};

describe("SupabaseRewardsRepository", () => {
  it("maps active scratch campaigns", async () => {
    const client = {
      from: (table: string) => {
        expect(table).toBe("scratch_card_campaigns");

        return {
          select: () => ({
            eq: () => ({
              maybeSingle: async () => ({
                data: campaignRow,
                error: null
              })
            })
          })
        };
      }
    };

    const repository = new SupabaseRewardsRepository(client as never);
    const campaign = await repository.findCampaign(campaignRow.id);

    expect(campaign).toMatchObject({
      active: true,
      costCoins: 10,
      id: campaignRow.id,
      probabilities: {
        common_discount_5: {
          discountPercent: 5,
          rarity: "common",
          weight: 90
        }
      }
    });
  });

  it("returns zero balance when wallet row is missing", async () => {
    const client = {
      from: (table: string) => {
        expect(table).toBe("coin_wallets");

        return {
          select: () => ({
            eq: () => ({
              maybeSingle: async () => ({
                data: null,
                error: null
              })
            })
          })
        };
      }
    };

    const repository = new SupabaseRewardsRepository(client as never);
    const wallet = await repository.getWallet("member-1");

    expect(wallet).toEqual({
      availableBalance: 0,
      userId: "member-1"
    });
  });

  it("maps scratch play RPC results", async () => {
    const client = {
      rpc: (name: string) => {
        expect(name).toBe("play_scratch_card_member");

        return {
          single: async () => ({
            data: {
              available_balance: 12,
              play_id: "play-1"
            },
            error: null
          })
        };
      }
    };

    const repository = new SupabaseRewardsRepository(client as never);
    const result = await repository.persistScratchPlay({
      campaignId: campaignRow.id,
      outcomeKey: "common_discount_5",
      userId: "member-1"
    });

    expect(result).toEqual({
      availableBalance: 12,
      playId: "play-1"
    });
  });

  it("translates INSUFFICIENT_BALANCE RPC failures", async () => {
    const client = {
      rpc: () => ({
        single: async () => ({
          data: null,
          error: { message: "INSUFFICIENT_BALANCE" }
        })
      })
    };

    const repository = new SupabaseRewardsRepository(client as never);

    await expect(
      repository.persistScratchPlay({
        campaignId: campaignRow.id,
        outcomeKey: "common_discount_5",
        userId: "member-1"
      })
    ).rejects.toMatchObject({
      code: "INSUFFICIENT_BALANCE"
    } satisfies Partial<AppError>);
  });

  it("maps persisted scratch plays", async () => {
    const client = {
      from: (table: string) => {
        expect(table).toBe("scratch_card_plays");

        return {
          select: () => ({
            eq: () => ({
              maybeSingle: async () => ({
                data: {
                  campaign_id: campaignRow.id,
                  id: "play-1",
                  outcome: "rare_discount_10",
                  user_id: "member-1"
                },
                error: null
              })
            })
          })
        };
      }
    };

    const repository = new SupabaseRewardsRepository(client as never);
    const play = await repository.findScratchPlay("play-1");

    expect(play).toEqual({
      campaignId: campaignRow.id,
      id: "play-1",
      outcome: "rare_discount_10",
      userId: "member-1"
    });
  });

  it("translates CAMPAIGN_INACTIVE RPC failures", async () => {
    const client = {
      rpc: () => ({
        single: async () => ({
          data: null,
          error: { message: "CAMPAIGN_INACTIVE" }
        })
      })
    };

    const repository = new SupabaseRewardsRepository(client as never);

    await expect(
      repository.persistScratchPlay({
        campaignId: campaignRow.id,
        outcomeKey: "common_discount_5",
        userId: "member-1"
      })
    ).rejects.toMatchObject({
      code: "CAMPAIGN_INACTIVE"
    } satisfies Partial<AppError>);
  });
});
