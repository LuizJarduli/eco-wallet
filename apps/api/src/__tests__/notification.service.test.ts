import { describe, expect, it, vi } from "vitest";

import type { Logger } from "../core/logger/logger.js";
import type { DeviceTokenRecord, DeviceTokenRepository } from "../features/notifications/device-token.repository.js";
import { createNotificationService } from "../features/notifications/notification.service.js";
import {
  rejectionDeepLink,
  rejectionPushBody,
  rejectionPushTitle
} from "../features/notifications/rejection-copy.js";
import type { PushMessage, PushProvider } from "../features/notifications/push-provider.js";

const silentLogger: Logger = {
  error: vi.fn(),
  info: vi.fn()
};

class InMemoryDeviceTokenRepository implements DeviceTokenRepository {
  constructor(private readonly tokens: DeviceTokenRecord[]) {}

  async listByUserId(userId: string): Promise<DeviceTokenRecord[]> {
    return this.tokens.filter((token) => token.userId === userId);
  }
}

class RecordingPushProvider implements PushProvider {
  readonly messages: PushMessage[] = [];

  async send(message: PushMessage): Promise<void> {
    this.messages.push(message);
  }
}

describe("rejection copy", () => {
  it("formats title and body from reasonCode", () => {
    expect(rejectionPushTitle).toBe("Descarte não aprovado");
    expect(rejectionPushBody("not_oil")).toContain("óleo de cozinha");
    expect(rejectionPushBody("not_oil")).toContain("novo descarte");
  });
});

describe("NotificationService.sendRejection", () => {
  it("skips outbound calls when push credentials are not configured", async () => {
    const provider = new RecordingPushProvider();
    const service = createNotificationService({
      deviceTokenRepository: new InMemoryDeviceTokenRepository([
        {
          id: "token-1",
          platform: "android",
          token: "android-token",
          userId: "member-1"
        }
      ]),
      log: silentLogger,
      pushProvider: null
    });

    await service.sendRejection({
      reasonCode: "not_oil",
      submissionId: "submission-1",
      userId: "member-1"
    });

    expect(provider.messages).toEqual([]);
    expect(silentLogger.info).toHaveBeenCalledWith(
      "rejection push skipped",
      expect.objectContaining({ reason: "push_provider_unconfigured" })
    );
  });

  it("skips outbound calls when the member has no device tokens", async () => {
    const provider = new RecordingPushProvider();
    const service = createNotificationService({
      deviceTokenRepository: new InMemoryDeviceTokenRepository([]),
      log: silentLogger,
      pushProvider: provider
    });

    await service.sendRejection({
      reasonCode: "not_oil",
      submissionId: "submission-1",
      userId: "member-1"
    });

    expect(provider.messages).toEqual([]);
    expect(silentLogger.info).toHaveBeenCalledWith(
      "rejection push skipped",
      expect.objectContaining({ reason: "no_device_tokens" })
    );
  });

  it("sends one push per registered device with deep link data", async () => {
    const provider = new RecordingPushProvider();
    const service = createNotificationService({
      deviceTokenRepository: new InMemoryDeviceTokenRepository([
        {
          id: "token-1",
          platform: "android",
          token: "android-token",
          userId: "member-1"
        },
        {
          id: "token-2",
          platform: "ios",
          token: "ios-token",
          userId: "member-1"
        }
      ]),
      log: silentLogger,
      pushProvider: provider
    });

    await service.sendRejection({
      reasonCode: "unclear_photo",
      submissionId: "submission-1",
      userId: "member-1"
    });

    expect(provider.messages).toHaveLength(2);
    expect(provider.messages[0]).toMatchObject({
      body: rejectionPushBody("unclear_photo"),
      data: {
        deepLink: rejectionDeepLink,
        reasonCode: "unclear_photo",
        submissionId: "submission-1"
      },
      title: rejectionPushTitle,
      token: "android-token"
    });
  });

  it("logs provider failures without throwing", async () => {
    const failingProvider: PushProvider = {
      send: async () => {
        throw new Error("provider down");
      }
    };
    const service = createNotificationService({
      deviceTokenRepository: new InMemoryDeviceTokenRepository([
        {
          id: "token-1",
          platform: "android",
          token: "android-token",
          userId: "member-1"
        }
      ]),
      log: silentLogger,
      pushProvider: failingProvider
    });

    await expect(
      service.sendRejection({
        reasonCode: "other",
        submissionId: "submission-1",
        userId: "member-1"
      })
    ).resolves.toBeUndefined();

    expect(silentLogger.error).toHaveBeenCalledWith(
      "rejection push failed",
      expect.objectContaining({ submissionId: "submission-1" })
    );
  });
});

describe("DisposalAdminService reject notifications", () => {
  it("calls the notification service once after a successful reject", async () => {
    const { createDisposalAdminService } = await import(
      "../features/disposals/disposal.service.js"
    );
    const sendRejection = vi.fn(async () => undefined);
    const submission = {
      confidenceStatus: "pending",
      estimatedLiters: null,
      id: "submission-1",
      locationScore: null,
      oilScore: null,
      rejectionReason: null,
      reviewPriority: "normal" as const,
      status: "submitted" as const,
      submittedAt: "2026-05-17T20:00:00.000Z",
      updatedAt: "2026-05-17T20:00:00.000Z",
      userId: "member-1"
    };
    const repository = {
      auditCollection: vi.fn(),
      approveSubmission: vi.fn(),
      findSubmission: vi.fn(async () => submission),
      getActiveRewardRule: vi.fn(),
      listAdminDisposals: vi.fn(),
      rejectSubmission: vi.fn(async () => undefined)
    };
    const service = createDisposalAdminService(repository, silentLogger, {
      sendRejection
    });

    await service.reject("submission-1", "admin-1", "not_oil");

    expect(repository.rejectSubmission).toHaveBeenCalledOnce();
    expect(sendRejection).toHaveBeenCalledWith({
      reasonCode: "not_oil",
      submissionId: "submission-1",
      userId: "member-1"
    });
  });
});
