import type { NextFunction, Request, RequestHandler, Response } from "express";

import { AppError } from "../../core/errors/app-error.js";
import type { ConfidenceService } from "./confidence.service.js";

const getMemberId = (req: Request): string => {
  if (!req.userId) {
    throw new AppError("UNAUTHORIZED", 401, "Authentication is required.");
  }

  return req.userId;
};

const getSubmissionId = (req: Request): string => {
  const { id } = req.params;

  if (typeof id !== "string" || id.trim().length === 0) {
    throw new AppError(
      "VALIDATION_ERROR",
      400,
      "Disposal submission id is required."
    );
  }

  return id;
};

const route =
  (handler: (req: Request, res: Response) => Promise<void>): RequestHandler =>
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      await handler(req, res);
    } catch (error) {
      next(error);
    }
  };

export const createConfidenceController = (
  service: ConfidenceService
): {
  score: RequestHandler;
} => ({
  score: route(async (req, res) => {
    const result = await service.scoreSubmission(
      getSubmissionId(req),
      getMemberId(req)
    );

    res.json({
      data: {
        confidenceStatus: result.submission.confidenceStatus,
        id: result.submission.id,
        idempotent: result.idempotent,
        locationScore: result.submission.locationScore,
        oilScore: result.submission.oilScore,
        reviewPriority: result.submission.reviewPriority
      }
    });
  })
});
