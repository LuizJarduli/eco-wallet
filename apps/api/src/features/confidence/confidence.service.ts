import type { ConfidenceInput, ConfidenceResult } from "@eco-wallet/domain";

import { AppError } from "../../core/errors/app-error.js";
import { logger, type Logger } from "../../core/logger/logger.js";
import type {
  ConfidenceRepository,
  ConfidenceScorer,
  ConfidenceSubmission,
  DropOffPoint,
  ReviewPriority
} from "./confidence.types.js";
import { createConfidenceScorer } from "./create-confidence-scorer.js";

export interface ConfidenceScoreResponse {
  submission: ConfidenceSubmission;
  idempotent: boolean;
}

export interface ConfidenceService {
  scoreSubmission(
    submissionId: string,
    memberId: string
  ): Promise<ConfidenceScoreResponse>;
}

export interface RetryOptions {
  maxAttempts: number;
  initialBackoffMs: number;
  delay: (durationMs: number) => Promise<void>;
}

const defaultRetryOptions: RetryOptions = {
  delay: (durationMs) =>
    new Promise((resolve) => {
      setTimeout(resolve, durationMs);
    }),
  initialBackoffMs: 100,
  maxAttempts: 3
};

const duplicateWindowMs = 60 * 60 * 1000;
const earthRadiusMeters = 6_371_000;

const ensureSubmission = async (
  repository: ConfidenceRepository,
  submissionId: string
): Promise<ConfidenceSubmission> => {
  const submission = await repository.findSubmission(submissionId);

  if (!submission) {
    throw new AppError(
      "DISPOSAL_NOT_FOUND",
      404,
      "Disposal submission was not found."
    );
  }

  return submission;
};

const toRadians = (value: number): number => (value * Math.PI) / 180;

export const distanceInMeters = (
  from: { latitude: number; longitude: number },
  to: { latitude: number; longitude: number }
): number => {
  const deltaLat = toRadians(to.latitude - from.latitude);
  const deltaLng = toRadians(to.longitude - from.longitude);
  const lat1 = toRadians(from.latitude);
  const lat2 = toRadians(to.latitude);
  const a =
    Math.sin(deltaLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(deltaLng / 2) ** 2;

  return 2 * earthRadiusMeters * Math.asin(Math.sqrt(a));
};

export const calculateLocationScore = (
  submission: ConfidenceSubmission,
  dropOffPoint: DropOffPoint | null
): number => {
  if (
    !dropOffPoint?.active ||
    submission.captureLat === null ||
    submission.captureLng === null
  ) {
    return 0;
  }

  const distance = distanceInMeters(
    {
      latitude: submission.captureLat,
      longitude: submission.captureLng
    },
    {
      latitude: dropOffPoint.latitude,
      longitude: dropOffPoint.longitude
    }
  );

  if (distance <= 100) {
    return 1;
  }

  if (distance >= 1_000) {
    return 0;
  }

  return Number((1 - (distance - 100) / 900).toFixed(3));
};

const determineReviewPriority = (
  oilScore: number,
  locationScore: number,
  duplicateDetected: boolean
): ReviewPriority => {
  if (duplicateDetected) {
    return "normal";
  }

  if (oilScore >= 0.85 && locationScore >= 0.75) {
    return "high";
  }

  if (oilScore < 0.5 || locationScore < 0.5) {
    return "low";
  }

  return "normal";
};

const withRetries = async <T>(
  action: () => Promise<T>,
  options: RetryOptions
): Promise<T> => {
  let lastError: unknown;

  for (let attempt = 1; attempt <= options.maxAttempts; attempt += 1) {
    try {
      return await action();
    } catch (error) {
      lastError = error;

      if (attempt < options.maxAttempts) {
        await options.delay(options.initialBackoffMs * 2 ** (attempt - 1));
      }
    }
  }

  throw lastError;
};

const errorMessage = (error: unknown): string =>
  error instanceof Error ? error.message : "Unknown confidence scoring error.";

export const createConfidenceService = (
  repository: ConfidenceRepository,
  scorer: ConfidenceScorer = createConfidenceScorer(),
  retryOptions: Partial<RetryOptions> = {},
  log: Logger = logger
): ConfidenceService => {
  const resolvedRetryOptions: RetryOptions = {
    ...defaultRetryOptions,
    ...retryOptions
  };

  return {
    async scoreSubmission(submissionId, memberId) {
      const submission = await ensureSubmission(repository, submissionId);

      if (submission.userId !== memberId) {
        throw new AppError(
          "FORBIDDEN",
          403,
          "Cannot score another member's disposal submission."
        );
      }

      if (submission.confidenceStatus !== "pending") {
        return { idempotent: true, submission };
      }

      let result: ConfidenceResult;
      try {
        const [imageUrl, dropOffPoint, duplicate] = await Promise.all([
          repository.createSignedImageUrl(submission.storagePath),
          repository.findDropOffPoint(submission.dropOffId),
          repository.findRecentDuplicate({
            excludeSubmissionId: submission.id,
            storagePath: submission.storagePath,
            submittedAfter: new Date(
              new Date(submission.submittedAt).getTime() - duplicateWindowMs
            ).toISOString(),
            userId: submission.userId
          })
        ]);

        const locationScore = calculateLocationScore(submission, dropOffPoint);
        const input: ConfidenceInput = {
          captureLat: submission.captureLat ?? 0,
          captureLng: submission.captureLng ?? 0,
          dropOffId: submission.dropOffId,
          imageUrl,
          submissionId
        };
        const scored = await withRetries(() => scorer.score(input), resolvedRetryOptions);
        const duplicateDetected = duplicate !== null;
        result = {
          ...scored,
          locationScore,
          raw: {
            ...(scored.raw ?? {}),
            duplicateDetected,
            duplicateSubmissionId: duplicate?.id ?? null,
            locationHeuristic: {
              activeDropOff: dropOffPoint?.active ?? false,
              captureCoordinatesPresent:
                submission.captureLat !== null && submission.captureLng !== null
            }
          },
          reviewPriority: determineReviewPriority(
            scored.oilScore,
            locationScore,
            duplicateDetected
          )
        };
      } catch (error) {
        const updated = await repository.markFailed(submissionId, {
          attempts: resolvedRetryOptions.maxAttempts,
          error: errorMessage(error)
        });

        log.error("confidence scoring failed", {
          error: errorMessage(error),
          submissionId
        });

        return { idempotent: false, submission: updated };
      }

      const updated = await repository.markReady(submissionId, result);

      log.info("confidence scoring completed", {
        provider: result.provider,
        reviewPriority: result.reviewPriority,
        submissionId
      });

      return { idempotent: false, submission: updated };
    }
  };
};
