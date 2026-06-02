import type {
  DisposalStatus,
  RejectionReasonCode
} from "@eco-wallet/domain";

import { AppError } from "../../core/errors/app-error.js";
import { logger, type Logger } from "../../core/logger/logger.js";
import type { NotificationService } from "../notifications/notification.service.js";
import type { ReviewPriority } from "./disposal.schema.js";

export interface DisposalSubmission {
  id: string;
  userId: string;
  status: DisposalStatus;
  rejectionReason: RejectionReasonCode | null;
  estimatedLiters: number | null;
  confidenceStatus: string;
  oilScore: number | null;
  locationScore: number | null;
  reviewPriority: ReviewPriority;
  submittedAt: string;
  updatedAt: string;
}

export interface RewardRule {
  id: string;
  coinsPerLiter: number;
  minLiters: number;
}

export interface AdminDisposalListFilters {
  status?: DisposalStatus;
  priority?: ReviewPriority;
}

export interface AdminDisposalListItem extends DisposalSubmission {
  storagePath: string;
}

export interface AuditResult {
  coinsReleased: number;
}

export interface DisposalRepository {
  findSubmission(submissionId: string): Promise<DisposalSubmission | null>;
  getActiveRewardRule(): Promise<RewardRule>;
  approveSubmission(input: {
    submissionId: string;
    adminId: string;
    estimatedLiters: number;
  }): Promise<{ pendingCoins: number }>;
  rejectSubmission(input: {
    submissionId: string;
    adminId: string;
    reasonCode: RejectionReasonCode;
    note?: string;
  }): Promise<void>;
  auditCollection(input: {
    submissionId: string;
    adminId: string;
    auditedLiters: number;
  }): Promise<AuditResult>;
  listAdminDisposals(
    filters: AdminDisposalListFilters
  ): Promise<AdminDisposalListItem[]>;
}

export interface DisposalAdminService {
  approve(
    submissionId: string,
    adminId: string,
    estimatedLiters: number
  ): Promise<{ pendingCoins: number }>;
  reject(
    submissionId: string,
    adminId: string,
    reasonCode: RejectionReasonCode,
    note?: string
  ): Promise<void>;
  auditCollection(
    submissionId: string,
    adminId: string,
    auditedLiters: number
  ): Promise<AuditResult>;
  listAdminDisposals(
    filters: AdminDisposalListFilters
  ): Promise<AdminDisposalListItem[]>;
}

const ensureSubmission = async (
  repository: DisposalRepository,
  submissionId: string
): Promise<DisposalSubmission> => {
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

const assertTransition = (
  currentStatus: DisposalStatus,
  expectedStatus: DisposalStatus
): void => {
  if (currentStatus !== expectedStatus) {
    throw new AppError(
      "INVALID_TRANSITION",
      409,
      `Cannot transition disposal from ${currentStatus}.`
    );
  }
};

export const createDisposalAdminService = (
  repository: DisposalRepository,
  log: Logger = logger,
  notifications?: NotificationService
): DisposalAdminService => ({
  async approve(submissionId, adminId, estimatedLiters) {
    const submission = await ensureSubmission(repository, submissionId);
    assertTransition(submission.status, "submitted");

    const result = await repository.approveSubmission({
      submissionId,
      adminId,
      estimatedLiters
    });

    log.info("disposal transition", {
      submissionId,
      adminId,
      transition: "submitted->awaiting_audit",
      auditedLiters: null,
      coinsReleased: 0
    });

    return result;
  },

  async reject(submissionId, adminId, reasonCode, note) {
    const submission = await ensureSubmission(repository, submissionId);

    if (!["submitted", "under_review"].includes(submission.status)) {
      throw new AppError(
        "INVALID_TRANSITION",
        409,
        `Cannot reject disposal from ${submission.status}.`
      );
    }

    await repository.rejectSubmission({
      submissionId,
      adminId,
      reasonCode,
      note
    });

    log.info("disposal transition", {
      submissionId,
      adminId,
      transition: `${submission.status}->rejected`,
      auditedLiters: null,
      coinsReleased: 0
    });

    if (notifications) {
      try {
        await notifications.sendRejection({
          reasonCode,
          submissionId,
          userId: submission.userId
        });
      } catch (error) {
        log.error("rejection push dispatch failed", {
          error,
          submissionId,
          userId: submission.userId
        });
      }
    }
  },

  async auditCollection(submissionId, adminId, auditedLiters) {
    const [submission, rewardRule] = await Promise.all([
      ensureSubmission(repository, submissionId),
      repository.getActiveRewardRule()
    ]);
    assertTransition(submission.status, "awaiting_audit");

    if (auditedLiters < rewardRule.minLiters) {
      throw new AppError(
        "BELOW_MIN_VOLUME",
        422,
        `Audited volume must be at least ${rewardRule.minLiters} liters.`
      );
    }

    const result = await repository.auditCollection({
      submissionId,
      adminId,
      auditedLiters
    });

    log.info("disposal transition", {
      submissionId,
      adminId,
      transition: "awaiting_audit->rewarded",
      auditedLiters,
      coinsReleased: result.coinsReleased
    });

    return result;
  },

  listAdminDisposals(filters) {
    return repository.listAdminDisposals(filters);
  }
});
