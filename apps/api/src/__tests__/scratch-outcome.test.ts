import { describe, expect, it } from "vitest";

import {
  parseScratchProbabilities,
  pickWeightedOutcome
} from "../features/rewards/scratch-outcome.js";

const mvpProbabilities = {
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
} as const;

describe("parseScratchProbabilities", () => {
  it("maps snake_case campaign config into service types", () => {
    const parsed = parseScratchProbabilities({
      common_discount_5: {
        discount_percent: 5,
        rarity: "common",
        weight: 90
      }
    });

    expect(parsed.common_discount_5).toEqual({
      discountPercent: 5,
      rarity: "common",
      weight: 90
    });
  });
});

describe("pickWeightedOutcome", () => {
  it("returns the only outcome when roll is zero", () => {
    const result = pickWeightedOutcome(mvpProbabilities, () => 0);

    expect(result.outcomeKey).toBe("common_discount_5");
    expect(result.config.discountPercent).toBe(5);
  });

  it("returns the rare outcome near the top of the weight range", () => {
    const result = pickWeightedOutcome(mvpProbabilities, () => 0.95);

    expect(result.outcomeKey).toBe("rare_discount_10");
    expect(result.config.discountPercent).toBe(10);
  });

  it("throws when probabilities are empty", () => {
    expect(() => pickWeightedOutcome({})).toThrow(
      "Scratch campaign probabilities are empty."
    );
  });

  it("throws when total weight is not positive", () => {
    expect(() =>
      pickWeightedOutcome({
        common_discount_5: {
          discountPercent: 5,
          rarity: "common",
          weight: 0
        }
      })
    ).toThrow("Scratch campaign probabilities must have positive total weight.");
  });

  it("distributes seeded MVP weights across 1000 mocked plays", () => {
    const totals = {
      common_discount_5: 0,
      rare_discount_10: 0
    };

    for (let index = 0; index < 1000; index += 1) {
      const result = pickWeightedOutcome(mvpProbabilities, () => index / 1000);
      totals[result.outcomeKey as keyof typeof totals] += 1;
    }

    expect(totals.common_discount_5).toBeGreaterThanOrEqual(870);
    expect(totals.common_discount_5).toBeLessThanOrEqual(930);
    expect(totals.rare_discount_10).toBeGreaterThanOrEqual(70);
    expect(totals.rare_discount_10).toBeLessThanOrEqual(130);
  });
});
