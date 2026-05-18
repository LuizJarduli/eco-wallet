import { z } from "zod";

export const disposalStatuses = [
  "submitted",
  "under_review",
  "approved",
  "awaiting_audit",
  "rewarded",
  "rejected"
] as const;

export const confidenceStatuses = ["pending", "ready", "failed"] as const;

export const coinEntryTypes = ["pending", "available", "spent"] as const;

export const rejectionReasonCodes = [
  "not_oil",
  "unclear_photo",
  "bottle_not_visible",
  "below_min_volume",
  "invalid_drop_off",
  "duplicate",
  "other"
] as const;

export const disposalStatusSchema = z.enum(disposalStatuses);
export const confidenceStatusSchema = z.enum(confidenceStatuses);
export const coinEntryTypeSchema = z.enum(coinEntryTypes);
export const rejectionReasonCodeSchema = z.enum(rejectionReasonCodes);

export type DisposalStatus = (typeof disposalStatuses)[number];
export type ConfidenceStatus = (typeof confidenceStatuses)[number];
export type CoinEntryType = (typeof coinEntryTypes)[number];
export type RejectionReasonCode = (typeof rejectionReasonCodes)[number];
