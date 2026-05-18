import type {
  ConfidenceInput,
  ConfidenceResult,
  ConfidenceScorer
} from "@eco-wallet/domain";

import { AppError } from "../../core/errors/app-error.js";

export interface VisionProviderResult {
  oilScore: number;
  raw?: Record<string, unknown>;
}

export interface VisionProvider {
  analyzeOilLikelihood(imageUrl: string): Promise<VisionProviderResult>;
}

const clampScore = (value: number): number => Math.min(Math.max(value, 0), 1);

const readVisionEnv = (env: NodeJS.ProcessEnv = process.env) => {
  const endpoint = env.VISION_API_URL;
  const apiKey = env.VISION_API_KEY;

  if (!endpoint || !apiKey) {
    throw new Error("Missing required vision provider environment variables.");
  }

  return { apiKey, endpoint };
};

export class HttpVisionProvider implements VisionProvider {
  constructor(
    private readonly config = readVisionEnv(),
    private readonly fetcher: typeof fetch = fetch
  ) {}

  async analyzeOilLikelihood(imageUrl: string): Promise<VisionProviderResult> {
    const response = await this.fetcher(this.config.endpoint, {
      body: JSON.stringify({ imageUrl }),
      headers: {
        authorization: `Bearer ${this.config.apiKey}`,
        "content-type": "application/json"
      },
      method: "POST"
    });

    if (!response.ok) {
      throw new AppError(
        "INTERNAL_ERROR",
        500,
        "Vision provider request failed."
      );
    }

    const payload = (await response.json()) as Record<string, unknown>;
    const rawScore = payload.oilScore ?? payload.score;

    if (typeof rawScore !== "number" || !Number.isFinite(rawScore)) {
      throw new AppError(
        "INTERNAL_ERROR",
        500,
        "Vision provider returned an invalid score."
      );
    }

    return {
      oilScore: clampScore(rawScore),
      raw: payload
    };
  }
}

export class VisionConfidenceScorer implements ConfidenceScorer {
  constructor(
    private readonly provider: VisionProvider = new HttpVisionProvider(),
    private readonly providerName = "vision-api"
  ) {}

  async score(input: ConfidenceInput): Promise<ConfidenceResult> {
    const result = await this.provider.analyzeOilLikelihood(input.imageUrl);

    return {
      oilScore: result.oilScore,
      locationScore: 1,
      provider: this.providerName,
      raw: result.raw,
      reviewPriority: result.oilScore >= 0.85 ? "high" : "normal"
    };
  }
}
