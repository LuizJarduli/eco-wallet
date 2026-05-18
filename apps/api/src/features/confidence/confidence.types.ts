import type {
  ConfidenceResult,
  ConfidenceScorer,
  ReviewPriority
} from "@eco-wallet/domain";

export type { ConfidenceResult, ConfidenceScorer, ReviewPriority };

export interface ConfidenceSubmission {
  id: string;
  userId: string;
  dropOffId: string;
  storagePath: string;
  confidenceStatus: "pending" | "ready" | "failed";
  oilScore: number | null;
  locationScore: number | null;
  reviewPriority: ReviewPriority;
  provider: string | null;
  raw: Record<string, unknown> | null;
  submittedAt: string;
  captureLat: number | null;
  captureLng: number | null;
}

export interface DropOffPoint {
  id: string;
  active: boolean;
  latitude: number;
  longitude: number;
}

export interface DuplicateCandidate {
  id: string;
  submittedAt: string;
}

export interface ConfidenceRepository {
  createSignedImageUrl(storagePath: string): Promise<string>;
  findSubmission(submissionId: string): Promise<ConfidenceSubmission | null>;
  findDropOffPoint(dropOffId: string): Promise<DropOffPoint | null>;
  findRecentDuplicate(input: {
    excludeSubmissionId: string;
    storagePath: string;
    submittedAfter: string;
    userId: string;
  }): Promise<DuplicateCandidate | null>;
  markReady(
    submissionId: string,
    result: ConfidenceResult
  ): Promise<ConfidenceSubmission>;
  markFailed(
    submissionId: string,
    metadata: Record<string, unknown>
  ): Promise<ConfidenceSubmission>;
}
