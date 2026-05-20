export interface ScratchOutcomeConfig {
  discountPercent: number;
  rarity: string;
  weight: number;
}

export type ScratchProbabilities = Record<string, ScratchOutcomeConfig>;

interface RawScratchOutcomeConfig {
  discount_percent: number;
  rarity: string;
  weight: number;
}

export type RawScratchProbabilities = Record<string, RawScratchOutcomeConfig>;

export const parseScratchProbabilities = (
  raw: RawScratchProbabilities
): ScratchProbabilities => {
  const parsed: ScratchProbabilities = {};

  for (const [key, value] of Object.entries(raw)) {
    parsed[key] = {
      discountPercent: value.discount_percent,
      rarity: value.rarity,
      weight: value.weight
    };
  }

  return parsed;
};

export interface WeightedScratchOutcome {
  outcomeKey: string;
  config: ScratchOutcomeConfig;
}

export const pickWeightedOutcome = (
  probabilities: ScratchProbabilities,
  random: () => number = Math.random
): WeightedScratchOutcome => {
  const entries = Object.entries(probabilities);

  if (entries.length === 0) {
    throw new Error("Scratch campaign probabilities are empty.");
  }

  const totalWeight = entries.reduce((sum, [, config]) => sum + config.weight, 0);

  if (totalWeight <= 0) {
    throw new Error("Scratch campaign probabilities must have positive total weight.");
  }

  let roll = random() * totalWeight;

  for (const [outcomeKey, config] of entries) {
    roll -= config.weight;

    if (roll < 0) {
      return { config, outcomeKey };
    }
  }

  const [outcomeKey, config] = entries[entries.length - 1];

  return { config, outcomeKey };
};
