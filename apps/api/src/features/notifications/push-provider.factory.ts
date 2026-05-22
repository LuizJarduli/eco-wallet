import { createApnsPushProvider } from "./apns-push-provider.js";
import { createFcmPushProvider } from "./fcm-push-provider.js";
import {
  CompositePushProvider,
  type DevicePlatform,
  type PushProvider
} from "./push-provider.js";

export interface PushEnv {
  fcmServerKey?: string;
  apnsKeyId?: string;
  apnsTeamId?: string;
  apnsBundleId?: string;
  apnsPrivateKey?: string;
  apnsUseSandbox?: string;
}

export const createPushProviderFromEnv = (
  env: PushEnv = process.env as PushEnv
): PushProvider | null => {
  const providers: Partial<Record<DevicePlatform, PushProvider>> = {};

  if (env.fcmServerKey) {
    const fcmProvider = createFcmPushProvider({ serverKey: env.fcmServerKey });
    providers.android = fcmProvider;
    providers.web = fcmProvider;
  }

  if (
    env.apnsKeyId &&
    env.apnsTeamId &&
    env.apnsBundleId &&
    env.apnsPrivateKey
  ) {
    providers.ios = createApnsPushProvider({
      bundleId: env.apnsBundleId,
      keyId: env.apnsKeyId,
      privateKey: env.apnsPrivateKey,
      teamId: env.apnsTeamId,
      useSandbox: env.apnsUseSandbox === "true"
    });
  }

  if (Object.keys(providers).length === 0) {
    return null;
  }

  return new CompositePushProvider(providers);
};
