import type { DisposalStatus } from "@eco-wallet/domain";

import { AppError } from "../../core/errors/app-error.js";
import {
  createSupabaseServiceClient,
  type SupabaseServiceClient
} from "../../core/supabase/service-client.js";
import type {
  AdminDisposalListFilters,
  AdminDisposalListItem,
  AuditResult,
  DisposalRepository,
  DisposalSubmission,
  RewardRule
} from "./disposal.service.js";

interface SupabaseErrorLike {
  message: string;
}

interface DisposalSubmissionRow {
  id: string;
  user_id: string;
  status: DisposalStatus;
  rejection_reason: DisposalSubmission["rejectionReason"];
  estimated_liters: string | number | null;
  confidence_status: string;
  oil_score: string | number | null;
  location_score: string | number | null;
  review_priority: DisposalSubmission["reviewPriority"];
  submitted_at: string;
  updated_at: string;
}

interface RewardRuleRow {
  id: string;
  coins_per_liter: number;
  min_liters: string | number;
}

interface ApproveRpcRow {
  pending_coins: number;
}

interface AuditRpcRow {
  coins_released: number;
}

const toNumber = (value: string | number | null): number | null => {
  if (value === null) {
    return null;
  }

  return typeof value === "number" ? value : Number(value);
};

const toSubmission = (row: DisposalSubmissionRow): DisposalSubmission => ({
  id: row.id,
  userId: row.user_id,
  status: row.status,
  rejectionReason: row.rejection_reason,
  estimatedLiters: toNumber(row.estimated_liters),
  confidenceStatus: row.confidence_status,
  oilScore: toNumber(row.oil_score),
  locationScore: toNumber(row.location_score),
  reviewPriority: row.review_priority,
  submittedAt: row.submitted_at,
  updatedAt: row.updated_at
});

const toRewardRule = (row: RewardRuleRow): RewardRule => ({
  id: row.id,
  coinsPerLiter: row.coins_per_liter,
  minLiters: Number(row.min_liters)
});

const throwIfDomainRpcError = (error: SupabaseErrorLike): never => {
  if (error.message.includes("DISPOSAL_NOT_FOUND")) {
    throw new AppError(
      "DISPOSAL_NOT_FOUND",
      404,
      "Disposal submission was not found."
    );
  }

  if (error.message.includes("INVALID_TRANSITION")) {
    throw new AppError(
      "INVALID_TRANSITION",
      409,
      "Disposal submission cannot transition from its current status."
    );
  }

  if (error.message.includes("BELOW_MIN_VOLUME")) {
    throw new AppError(
      "BELOW_MIN_VOLUME",
      422,
      "Audited volume is below the active minimum."
    );
  }

  throw new AppError(
    "INTERNAL_ERROR",
    500,
    "Disposal persistence operation failed."
  );
};

export class SupabaseDisposalRepository implements DisposalRepository {
  constructor(
    private readonly client: SupabaseServiceClient = createSupabaseServiceClient()
  ) {}

  async findSubmission(
    submissionId: string
  ): Promise<DisposalSubmission | null> {
    const { data, error } = await this.client
      .from("disposal_submissions")
      .select(
        [
          "id",
          "user_id",
          "status",
          "rejection_reason",
          "estimated_liters",
          "confidence_status",
          "oil_score",
          "location_score",
          "review_priority",
          "submitted_at",
          "updated_at"
        ].join(",")
      )
      .eq("id", submissionId)
      .maybeSingle<DisposalSubmissionRow>();

    if (error) {
      throwIfDomainRpcError(error);
    }

    return data ? toSubmission(data) : null;
  }

  async getActiveRewardRule(): Promise<RewardRule> {
    const { data, error } = await this.client
      .from("reward_rules")
      .select("id,coins_per_liter,min_liters")
      .eq("active", true)
      .order("effective_from", { ascending: false })
      .limit(1)
      .single<RewardRuleRow>();

    if (error || !data) {
      throw new AppError(
        "INTERNAL_ERROR",
        500,
        "Active reward rule was not found."
      );
    }

    return toRewardRule(data);
  }

  async approveSubmission(input: {
    submissionId: string;
    adminId: string;
    estimatedLiters: number;
  }): Promise<{ pendingCoins: number }> {
    const { data, error } = await this.client
      .rpc("approve_disposal_admin", {
        p_admin_id: input.adminId,
        p_estimated_liters: input.estimatedLiters,
        p_submission_id: input.submissionId
      })
      .single<ApproveRpcRow>();

    if (error) {
      throwIfDomainRpcError(error);
    }

    if (!data) {
      throw new AppError(
        "INTERNAL_ERROR",
        500,
        "Approve operation did not return a result."
      );
    }

    return { pendingCoins: data.pending_coins };
  }

  async rejectSubmission(input: {
    submissionId: string;
    adminId: string;
    reasonCode: DisposalSubmission["rejectionReason"];
    note?: string;
  }): Promise<void> {
    const { error } = await this.client
      .from("disposal_submissions")
      .update({
        rejection_reason: input.reasonCode,
        status: "rejected"
      })
      .eq("id", input.submissionId)
      .in("status", ["submitted", "under_review"]);

    if (error) {
      throwIfDomainRpcError(error);
    }
  }

  async auditCollection(input: {
    submissionId: string;
    adminId: string;
    auditedLiters: number;
  }): Promise<AuditResult> {
    const { data, error } = await this.client
      .rpc("audit_disposal_collection_admin", {
        p_admin_id: input.adminId,
        p_audited_liters: input.auditedLiters,
        p_submission_id: input.submissionId
      })
      .single<AuditRpcRow>();

    if (error) {
      throwIfDomainRpcError(error);
    }

    if (!data) {
      throw new AppError(
        "INTERNAL_ERROR",
        500,
        "Audit operation did not return a result."
      );
    }

    return { coinsReleased: data.coins_released };
  }

  async listAdminDisposals(
    filters: AdminDisposalListFilters
  ): Promise<AdminDisposalListItem[]> {
    let query = this.client
      .from("disposal_submissions")
      .select(
        [
          "id",
          "user_id",
          "status",
          "rejection_reason",
          "estimated_liters",
          "confidence_status",
          "oil_score",
          "location_score",
          "review_priority",
          "submitted_at",
          "updated_at"
        ].join(",")
      )
      .order("submitted_at", { ascending: false });

    if (filters.status) {
      query = query.eq("status", filters.status);
    }

    if (filters.priority) {
      query = query.eq("review_priority", filters.priority);
    }

    const { data, error } = await query.returns<DisposalSubmissionRow[]>();

    if (error) {
      throwIfDomainRpcError(error);
    }

    return (data ?? []).map(toSubmission);
  }
}
