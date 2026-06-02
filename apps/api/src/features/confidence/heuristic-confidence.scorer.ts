import type {
  ConfidenceInput,
  ConfidenceResult,
  ConfidenceScorer
} from "@eco-wallet/domain";

/**
 * Fallback when no vision provider is configured (typical local dev).
 * Produces a neutral oil score so submissions still reach the review queue.
 */
export class HeuristicConfidenceScorer implements ConfidenceScorer {
  constructor(private readonly providerName = "heuristic-dev") {}

  async score(_input: ConfidenceInput): Promise<ConfidenceResult> {
    return {
      locationScore: 1,
      oilScore: 0.65,
      provider: this.providerName,
      raw: {
        note: "Vision API not configured; using heuristic score for local development."
      },
      reviewPriority: "normal"
    };
  }
}
