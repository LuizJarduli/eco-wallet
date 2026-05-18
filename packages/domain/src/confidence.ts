export type ReviewPriority = "low" | "normal" | "high";

export interface ConfidenceInput {
  submissionId: string;
  imageUrl: string;
  dropOffId: string;
  captureLat: number;
  captureLng: number;
}

export interface ConfidenceResult {
  oilScore: number;
  locationScore: number;
  reviewPriority: ReviewPriority;
  provider: string;
  raw?: Record<string, unknown>;
}

export interface ConfidenceScorer {
  score(input: ConfidenceInput): Promise<ConfidenceResult>;
}
