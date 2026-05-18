import type { NextFunction, Request, RequestHandler, Response } from "express";
import { ZodError, type ZodType } from "zod";

import { AppError } from "../../core/errors/app-error.js";
import {
  approveDisposalBodySchema,
  auditDisposalBodySchema,
  listDisposalsQuerySchema,
  rejectDisposalBodySchema
} from "./disposal.schema.js";
import type { DisposalAdminService } from "./disposal.service.js";

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

const getAdminId = (req: Request): string => {
  if (!req.userId) {
    throw new AppError("UNAUTHORIZED", 401, "Authentication is required.");
  }

  return req.userId;
};

const getSubmissionId = (req: Request): string => {
  const { id } = req.params;

  if (typeof id !== "string") {
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

export const createDisposalController = (
  service: DisposalAdminService
): {
  list: RequestHandler;
  approve: RequestHandler;
  reject: RequestHandler;
  audit: RequestHandler;
} => ({
  list: route(async (req, res) => {
    const filters = parseOrThrow(listDisposalsQuerySchema, {
      priority: req.query.priority,
      status: req.query.status
    });
    const disposals = await service.listAdminDisposals(filters);

    res.json({ data: disposals });
  }),

  approve: route(async (req, res) => {
    const body = parseOrThrow(approveDisposalBodySchema, req.body);
    const result = await service.approve(
      getSubmissionId(req),
      getAdminId(req),
      body.estimatedLiters
    );

    res.json({ data: result });
  }),

  reject: route(async (req, res) => {
    const body = parseOrThrow(rejectDisposalBodySchema, req.body);

    await service.reject(
      getSubmissionId(req),
      getAdminId(req),
      body.reasonCode,
      body.note
    );

    res.status(204).send();
  }),

  audit: route(async (req, res) => {
    const body = parseOrThrow(auditDisposalBodySchema, req.body);
    const result = await service.auditCollection(
      getSubmissionId(req),
      getAdminId(req),
      body.auditedLiters
    );

    res.json({ data: result });
  })
});
