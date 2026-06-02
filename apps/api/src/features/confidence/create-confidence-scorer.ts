import type { ConfidenceScorer } from "@eco-wallet/domain";

import { logger } from "../../core/logger/logger.js";
import { HeuristicConfidenceScorer } from "./heuristic-confidence.scorer.js";
import {
  HttpVisionProvider,
  VisionConfidenceScorer
} from "./vision-confidence.scorer.js";

export const createConfidenceScorer = (
  env: NodeJS.ProcessEnv = process.env
): ConfidenceScorer => {
  const endpoint = env.VISION_API_URL?.trim();
  const apiKey = env.VISION_API_KEY?.trim();

  if (endpoint && apiKey) {
    return new VisionConfidenceScorer(
      new HttpVisionProvider({ apiKey, endpoint })
    );
  }

  logger.info(
    "VISION_API_URL / VISION_API_KEY not set; using heuristic confidence scorer"
  );

  return new HeuristicConfidenceScorer();
};
