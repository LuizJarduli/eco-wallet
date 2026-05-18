import { z } from "zod";

import { rejectionReasonCodeSchema } from "../enums.js";

const litersSchema = z.number().finite();

export const approveDisposalBodySchema = z
  .object({
    estimatedLiters: litersSchema.positive()
  })
  .strict();

export const rejectDisposalBodySchema = z
  .object({
    reasonCode: rejectionReasonCodeSchema,
    note: z.string().trim().min(1).max(500).optional()
  })
  .strict();

export const auditDisposalBodySchema = z
  .object({
    auditedLiters: litersSchema.positive()
  })
  .strict();

export const createAuditDisposalBodySchema = (minLiters: number) =>
  z
    .object({
      auditedLiters: litersSchema.min(minLiters)
    })
    .strict();

export type ApproveDisposalBody = z.infer<typeof approveDisposalBodySchema>;
export type RejectDisposalBody = z.infer<typeof rejectDisposalBodySchema>;
export type AuditDisposalBody = z.infer<typeof auditDisposalBodySchema>;
