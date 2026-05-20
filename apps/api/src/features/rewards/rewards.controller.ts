import type { NextFunction, Request, RequestHandler, Response } from "express";
import { scratchPlayBodySchema } from "@eco-wallet/domain";
import { ZodError, type ZodType } from "zod";

import { AppError } from "../../core/errors/app-error.js";
import type { ScratchRewardsService } from "./rewards.service.js";

const parseOrThrow = <T>(schema: ZodType<T>, value: unknown): T => {
  try {
    return schema.parse(value);
  } catch (error) {
    if (error instanceof ZodError) {
      throw new AppError(
        "VALIDATION_ERROR",
        400,
        error.issues[0]?.message ?? "Request validation failed."
      );
    }

    throw error;
  }
};

const getMemberId = (req: Request): string => {
  if (!req.userId) {
    throw new AppError("UNAUTHORIZED", 401, "Authentication is required.");
  }

  return req.userId;
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

export const createRewardsController = (
  service: ScratchRewardsService
): {
  playScratch: RequestHandler;
} => ({
  playScratch: route(async (req, res) => {
    const body = parseOrThrow(scratchPlayBodySchema, req.body);
    const result = await service.playScratch(getMemberId(req), body.campaignId);

    res.status(201).json({ data: result });
  })
});
