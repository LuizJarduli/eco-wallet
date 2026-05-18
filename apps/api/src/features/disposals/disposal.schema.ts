import {
  approveDisposalBodySchema,
  auditDisposalBodySchema,
  disposalStatusSchema,
  rejectDisposalBodySchema
} from "@eco-wallet/domain";
import { z } from "zod";

export {
  approveDisposalBodySchema,
  auditDisposalBodySchema,
  rejectDisposalBodySchema
};

export const reviewPrioritySchema = z.enum(["low", "normal", "high"]);

export const listDisposalsQuerySchema = z
  .object({
    status: disposalStatusSchema.optional(),
    priority: reviewPrioritySchema.optional()
  })
  .strict();

export type ListDisposalsQuery = z.infer<typeof listDisposalsQuerySchema>;
export type ReviewPriority = z.infer<typeof reviewPrioritySchema>;
