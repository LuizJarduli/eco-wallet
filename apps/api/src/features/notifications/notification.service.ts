import type { RejectionReasonCode } from "@eco-wallet/domain";

import type { Logger } from "../../core/logger/logger.js";
import { logger } from "../../core/logger/logger.js";
import type { DeviceTokenRepository } from "./device-token.repository.js";
import { SupabaseDeviceTokenRepository } from "./device-token.repository.js";
import type { PushProvider } from "./push-provider.js";
import {
  rejectionDeepLink,
  rejectionPushBody,
  rejectionPushTitle
} from "./rejection-copy.js";

export interface RejectionNotificationInput {
  userId: string;
  submissionId: string;
  reasonCode: RejectionReasonCode;
}

export interface NotificationService {
  sendRejection(input: RejectionNotificationInput): Promise<void>;
}

export interface NotificationServiceDependencies {
  deviceTokenRepository?: DeviceTokenRepository;
  pushProvider?: PushProvider | null;
  log?: Logger;
}

export const createNotificationService = ({
  deviceTokenRepository = new SupabaseDeviceTokenRepository(),
  pushProvider = null,
  log = logger
}: NotificationServiceDependencies = {}): NotificationService => ({
  async sendRejection({ userId, submissionId, reasonCode }) {
    const tokens = await deviceTokenRepository.listByUserId(userId);

    if (tokens.length === 0) {
      log.info("rejection push skipped", {
        reason: "no_device_tokens",
        submissionId,
        userId
      });
      return;
    }

    if (!pushProvider) {
      log.info("rejection push skipped", {
        reason: "push_provider_unconfigured",
        submissionId,
        tokenCount: tokens.length,
        userId
      });
      return;
    }

    const title = rejectionPushTitle;
    const body = rejectionPushBody(reasonCode);
    const data = {
      deepLink: rejectionDeepLink,
      reasonCode,
      submissionId
    };

    await Promise.all(
      tokens.map(async (deviceToken) => {
        try {
          await pushProvider.send({
            body,
            data,
            platform: deviceToken.platform,
            title,
            token: deviceToken.token
          });
        } catch (error) {
          log.error("rejection push failed", {
            deviceTokenId: deviceToken.id,
            error,
            platform: deviceToken.platform,
            submissionId,
            userId
          });
        }
      })
    );
  }
});
