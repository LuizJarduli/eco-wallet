import { z } from "zod";

export const domainErrorCodes = [
  "UNAUTHORIZED",
  "FORBIDDEN",
  "VALIDATION_ERROR",
  "NOT_FOUND",
  "INTERNAL_ERROR",
  "DISPOSAL_NOT_FOUND",
  "INVALID_TRANSITION",
  "BELOW_MIN_VOLUME",
  "INSUFFICIENT_BALANCE",
  "CAMPAIGN_INACTIVE"
] as const;

export const domainErrorCodeSchema = z.enum(domainErrorCodes);

export const apiErrorResponseSchema = z
  .object({
    error: z.object({
      code: domainErrorCodeSchema,
      message: z.string().min(1)
    })
  })
  .strict();

export type DomainErrorCode = (typeof domainErrorCodes)[number];
export type ApiErrorResponse = z.infer<typeof apiErrorResponseSchema>;
