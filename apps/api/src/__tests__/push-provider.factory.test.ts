import { describe, expect, it } from "vitest";

import { CompositePushProvider } from "../features/notifications/push-provider.js";
import { createPushProviderFromEnv } from "../features/notifications/push-provider.factory.js";

describe("createPushProviderFromEnv", () => {
  it("returns null when no credentials are configured", () => {
    expect(createPushProviderFromEnv({})).toBeNull();
  });

  it("wires FCM for android and web when only the server key is set", () => {
    const provider = createPushProviderFromEnv({
      fcmServerKey: "server-key"
    });

    expect(provider).toBeInstanceOf(CompositePushProvider);
  });

  it("wires APNs for ios when APNs credentials are set", () => {
    const provider = createPushProviderFromEnv({
      apnsBundleId: "com.example.app",
      apnsKeyId: "KEY",
      apnsPrivateKey: "-----BEGIN PRIVATE KEY-----\nMIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg\n-----END PRIVATE KEY-----",
      apnsTeamId: "TEAM"
    });

    expect(provider).toBeInstanceOf(CompositePushProvider);
  });
});
