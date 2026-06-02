import type {
  DisposalStatus,
  RejectionReasonCode
} from "@eco-wallet/domain";
import request from "supertest";
import { beforeEach, describe, expect, it } from "vitest";

import { AppError } from "../core/errors/app-error.js";
import { createApp } from "../core/http/app.js";
import type { Logger } from "../core/logger/logger.js";
import { createNotificationService } from "../features/notifications/notification.service.js";
import type { PushMessage, PushProvider } from "../features/notifications/push-provider.js";
import {
  createDisposalAdminService,
  type AdminDisposalListFilters,
  type AdminDisposalListItem,
  type AuditResult,
  type DisposalRepository,
  type DisposalSubmission,
  type RewardRule
} from "../features/disposals/disposal.service.js";
import { createJwtVerifier, createRoleLookup } from "../test/fakes.js";

const silentLogger: Logger = {
  error: () => undefined,
  info: () => undefined
};

interface Wallet {
  pendingBalance: number;
  availableBalance: number;
}

interface LedgerEntry {
  walletUserId: string;
  amount: number;
  type: "pending" | "available";
  referenceId: string;
}

const createSubmission = (
  overrides: Partial<AdminDisposalListItem> = {}
): AdminDisposalListItem => ({
  confidenceStatus: "pending",
  estimatedLiters: null,
  id: "submission-1",
  locationScore: null,
  oilScore: null,
  rejectionReason: null,
  reviewPriority: "normal",
  status: "submitted",
  storagePath: "member-1/submission-1.jpg",
  submittedAt: "2026-05-17T20:00:00.000Z",
  updatedAt: "2026-05-17T20:00:00.000Z",
  userId: "member-1",
  ...overrides
});

class InMemoryDisposalRepository implements DisposalRepository {
  readonly audits: Array<{
    submissionId: string;
    adminId: string;
    auditedLiters: number;
  }> = [];

  readonly coinLedger: LedgerEntry[] = [];

  readonly inventoryLedger: Array<{
    deltaLiters: number;
    sourceSubmissionId: string;
  }> = [];

  readonly wallets = new Map<string, Wallet>();

  constructor(
    private readonly submissions: AdminDisposalListItem[],
    private readonly rewardRule: RewardRule = {
      coinsPerLiter: 10,
      id: "rule-1",
      minLiters: 1
    }
  ) {}

  async findSubmission(
    submissionId: string
  ): Promise<DisposalSubmission | null> {
    return this.submissions.find((submission) => submission.id === submissionId) ?? null;
  }

  async getActiveRewardRule(): Promise<RewardRule> {
    return this.rewardRule;
  }

  async approveSubmission(input: {
    submissionId: string;
    adminId: string;
    estimatedLiters: number;
  }): Promise<{ pendingCoins: number }> {
    const submission = await this.findSubmission(input.submissionId);

    if (!submission) {
      throw new AppError(
        "DISPOSAL_NOT_FOUND",
        404,
        "Disposal submission was not found."
      );
    }

    const pendingCoins =
      Math.floor(input.estimatedLiters) * this.rewardRule.coinsPerLiter;
    submission.status = "awaiting_audit";
    submission.estimatedLiters = input.estimatedLiters;

    const wallet = this.wallets.get(submission.userId) ?? {
      availableBalance: 0,
      pendingBalance: 0
    };
    wallet.pendingBalance += pendingCoins;
    this.wallets.set(submission.userId, wallet);

    if (pendingCoins > 0) {
      this.coinLedger.push({
        amount: pendingCoins,
        referenceId: input.submissionId,
        type: "pending",
        walletUserId: submission.userId
      });
    }

    return { pendingCoins };
  }

  async rejectSubmission(input: {
    submissionId: string;
    adminId: string;
    reasonCode: RejectionReasonCode;
    note?: string;
  }): Promise<void> {
    const submission = await this.findSubmission(input.submissionId);

    if (!submission) {
      throw new AppError(
        "DISPOSAL_NOT_FOUND",
        404,
        "Disposal submission was not found."
      );
    }

    submission.status = "rejected";
    submission.rejectionReason = input.reasonCode;
  }

  async auditCollection(input: {
    submissionId: string;
    adminId: string;
    auditedLiters: number;
  }): Promise<AuditResult> {
    const submission = await this.findSubmission(input.submissionId);

    if (!submission) {
      throw new AppError(
        "DISPOSAL_NOT_FOUND",
        404,
        "Disposal submission was not found."
      );
    }

    const coinsReleased =
      Math.floor(input.auditedLiters) * this.rewardRule.coinsPerLiter;
    const pendingForSubmission = this.coinLedger
      .filter(
        (entry) =>
          entry.referenceId === input.submissionId && entry.type === "pending"
      )
      .reduce((sum, entry) => sum + entry.amount, 0);
    const wallet = this.wallets.get(submission.userId) ?? {
      availableBalance: 0,
      pendingBalance: 0
    };

    wallet.pendingBalance = Math.max(
      wallet.pendingBalance - pendingForSubmission,
      0
    );
    wallet.availableBalance += coinsReleased;
    this.wallets.set(submission.userId, wallet);

    this.audits.push({
      adminId: input.adminId,
      auditedLiters: input.auditedLiters,
      submissionId: input.submissionId
    });
    this.inventoryLedger.push({
      deltaLiters: input.auditedLiters,
      sourceSubmissionId: input.submissionId
    });
    this.coinLedger.push({
      amount: coinsReleased,
      referenceId: input.submissionId,
      type: "available",
      walletUserId: submission.userId
    });
    submission.status = "rewarded";

    return { coinsReleased };
  }

  async listAdminDisposals(
    filters: AdminDisposalListFilters
  ): Promise<AdminDisposalListItem[]> {
    return this.submissions.filter((submission) => {
      const matchesStatus = filters.status
        ? submission.status === filters.status
        : true;
      const matchesPriority = filters.priority
        ? submission.reviewPriority === filters.priority
        : true;

      return matchesStatus && matchesPriority;
    });
  }
}

describe("DisposalAdminService", () => {
  it("approve on submitted moves to awaiting_audit", async () => {
    const submission = createSubmission();
    const repository = new InMemoryDisposalRepository([submission]);
    const service = createDisposalAdminService(repository, silentLogger);

    const result = await service.approve("submission-1", "admin-1", 2);

    expect(result).toEqual({ pendingCoins: 20 });
    expect(submission.status).toBe("awaiting_audit");
    expect(submission.estimatedLiters).toBe(2);
    expect(repository.wallets.get("member-1")).toEqual({
      availableBalance: 0,
      pendingBalance: 20
    });
  });

  it("approve on rejected returns INVALID_TRANSITION", async () => {
    const repository = new InMemoryDisposalRepository([
      createSubmission({ status: "rejected" })
    ]);
    const service = createDisposalAdminService(repository, silentLogger);

    await expect(service.approve("submission-1", "admin-1", 2)).rejects.toMatchObject({
      code: "INVALID_TRANSITION"
    });
  });

  it("approve on an unknown submission returns DISPOSAL_NOT_FOUND", async () => {
    const repository = new InMemoryDisposalRepository([]);
    const service = createDisposalAdminService(repository, silentLogger);

    await expect(service.approve("missing", "admin-1", 2)).rejects.toMatchObject({
      code: "DISPOSAL_NOT_FOUND"
    });
  });

  it("reject on submitted records the rejection reason", async () => {
    const submission = createSubmission();
    const repository = new InMemoryDisposalRepository([submission]);
    const service = createDisposalAdminService(repository, silentLogger);

    await service.reject("submission-1", "admin-1", "unclear_photo", "Too dark.");

    expect(submission).toMatchObject({
      rejectionReason: "unclear_photo",
      status: "rejected"
    });
  });

  it("reject without device tokens still completes", async () => {
    const submission = createSubmission();
    const repository = new InMemoryDisposalRepository([submission]);
    const provider: PushProvider = {
      send: async () => {
        throw new Error("should not be called");
      }
    };
    const service = createDisposalAdminService(
      repository,
      silentLogger,
      createNotificationService({
        deviceTokenRepository: {
          listByUserId: async () => []
        },
        pushProvider: provider
      })
    );

    await expect(
      service.reject("submission-1", "admin-1", "not_oil")
    ).resolves.toBeUndefined();
    expect(submission.status).toBe("rejected");
  });

  it("reject after approval returns INVALID_TRANSITION", async () => {
    const repository = new InMemoryDisposalRepository([
      createSubmission({ status: "awaiting_audit" })
    ]);
    const service = createDisposalAdminService(repository, silentLogger);

    await expect(
      service.reject("submission-1", "admin-1", "not_oil")
    ).rejects.toMatchObject({
      code: "INVALID_TRANSITION"
    });
  });

  it("audit with 0.5 L when min is 1 L returns BELOW_MIN_VOLUME", async () => {
    const repository = new InMemoryDisposalRepository([
      createSubmission({ estimatedLiters: 1, status: "awaiting_audit" })
    ]);
    const service = createDisposalAdminService(repository, silentLogger);

    await expect(
      service.auditCollection("submission-1", "admin-1", 0.5)
    ).rejects.toMatchObject({
      code: "BELOW_MIN_VOLUME"
    });
  });

  it("audit before approval returns INVALID_TRANSITION", async () => {
    const repository = new InMemoryDisposalRepository([createSubmission()]);
    const service = createDisposalAdminService(repository, silentLogger);

    await expect(
      service.auditCollection("submission-1", "admin-1", 2)
    ).rejects.toMatchObject({
      code: "INVALID_TRANSITION"
    });
  });

  it("audit with 2 L at 10 coins/L credits 20 available coins", async () => {
    const submission = createSubmission();
    const repository = new InMemoryDisposalRepository([submission]);
    const service = createDisposalAdminService(repository, silentLogger);

    await service.approve("submission-1", "admin-1", 2);
    const result = await service.auditCollection("submission-1", "admin-1", 2);

    expect(result).toEqual({ coinsReleased: 20 });
    expect(repository.wallets.get("member-1")).toEqual({
      availableBalance: 20,
      pendingBalance: 0
    });
    expect(submission.status).toBe("rewarded");
  });
});

describe("admin disposal API", () => {
  let repository: InMemoryDisposalRepository;

  beforeEach(() => {
    repository = new InMemoryDisposalRepository([
      createSubmission({ id: "submitted-1", status: "submitted" }),
      createSubmission({ id: "approved-1", status: "awaiting_audit" }),
      createSubmission({ id: "rewarded-1", status: "rewarded" })
    ]);
  });

  const createTestApp = () =>
    createApp({
      disposalAdminService: createDisposalAdminService(repository, silentLogger),
      disposalRepository: repository,
      jwtVerifier: createJwtVerifier("admin-1"),
      profileRoleLookup: createRoleLookup("admin")
    });

  it("approve then audit creates inventory ledger row and rewarded status", async () => {
    await request(createTestApp())
      .post("/v1/admin/disposals/submitted-1/approve")
      .set("Authorization", "Bearer valid-token")
      .send({ estimatedLiters: 2 })
      .expect(200);

    const response = await request(createTestApp())
      .post("/v1/admin/disposals/submitted-1/audit")
      .set("Authorization", "Bearer valid-token")
      .send({ auditedLiters: 2 })
      .expect(200);

    expect(response.body).toEqual({ data: { coinsReleased: 20 } });
    expect(repository.inventoryLedger).toEqual([
      { deltaLiters: 2, sourceSubmissionId: "submitted-1" }
    ]);
    expect(repository.audits).toEqual([
      {
        adminId: "admin-1",
        auditedLiters: 2,
        submissionId: "submitted-1"
      }
    ]);
    expect(await repository.findSubmission("submitted-1")).toMatchObject({
      status: "rewarded"
    });
  });

  it("GET /v1/admin/disposals?status=awaiting_audit returns approved items only", async () => {
    const response = await request(createTestApp())
      .get("/v1/admin/disposals?status=awaiting_audit")
      .set("Authorization", "Bearer valid-token")
      .expect(200);

    expect(
      response.body.data.map((item: { id: string }) => item.id)
    ).toEqual(["approved-1"]);
    expect(
      response.body.data.every(
        (item: { status: DisposalStatus }) => item.status === "awaiting_audit"
      )
    ).toBe(true);
  });

  it("reject endpoint records a reason and returns no content", async () => {
    await request(createTestApp())
      .post("/v1/admin/disposals/submitted-1/reject")
      .set("Authorization", "Bearer valid-token")
      .send({ reasonCode: "not_oil" })
      .expect(204);

    await expect(repository.findSubmission("submitted-1")).resolves.toMatchObject({
      rejectionReason: "not_oil",
      status: "rejected"
    });
  });

  it("POST reject with mocked provider records one outbound call per device", async () => {
    const outbound: PushMessage[] = [];
    const notificationService = createNotificationService({
      deviceTokenRepository: {
        listByUserId: async () => [
          {
            id: "token-1",
            platform: "android",
            token: "device-token",
            userId: "member-1"
          }
        ]
      },
      log: silentLogger,
      pushProvider: {
        send: async (message) => {
          outbound.push(message);
        }
      }
    });
    const service = createDisposalAdminService(
      repository,
      silentLogger,
      notificationService
    );

    await request(
      createApp({
        disposalAdminService: service,
        disposalRepository: repository,
        jwtVerifier: createJwtVerifier("admin-1"),
        profileRoleLookup: createRoleLookup("admin")
      })
    )
      .post("/v1/admin/disposals/submitted-1/reject")
      .set("Authorization", "Bearer valid-token")
      .send({ reasonCode: "unclear_photo" })
      .expect(204);

    expect(outbound).toHaveLength(1);
    expect(outbound[0]).toMatchObject({
      data: expect.objectContaining({
        deepLink: "ecowallet://disposal/submit",
        reasonCode: "unclear_photo",
        submissionId: "submitted-1"
      }),
      token: "device-token"
    });
  });

  it("returns VALIDATION_ERROR for invalid approve bodies", async () => {
    const response = await request(createTestApp())
      .post("/v1/admin/disposals/submitted-1/approve")
      .set("Authorization", "Bearer valid-token")
      .send({ estimatedLiters: -1 })
      .expect(400);

    expect(response.body.error.code).toBe("VALIDATION_ERROR");
  });
});
