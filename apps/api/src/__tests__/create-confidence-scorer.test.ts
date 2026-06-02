import { describe, expect, it } from "vitest";

import { createConfidenceScorer } from "../features/confidence/create-confidence-scorer.js";
import { HeuristicConfidenceScorer } from "../features/confidence/heuristic-confidence.scorer.js";
import { VisionConfidenceScorer } from "../features/confidence/vision-confidence.scorer.js";

describe("createConfidenceScorer", () => {
  it("returns heuristic scorer when vision env is missing", () => {
    const scorer = createConfidenceScorer({});

    expect(scorer).toBeInstanceOf(HeuristicConfidenceScorer);
  });

  it("returns vision scorer when vision env is configured", () => {
    const scorer = createConfidenceScorer({
      VISION_API_KEY: "secret",
      VISION_API_URL: "https://vision.test/score"
    });

    expect(scorer).toBeInstanceOf(VisionConfidenceScorer);
  });
});
