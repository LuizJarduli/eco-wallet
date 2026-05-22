import { describe, expect, it, vi } from "vitest";

import {
  CompositePushProvider,
  type PushProvider
} from "../features/notifications/push-provider.js";

describe("CompositePushProvider", () => {
  it("delegates to the provider for the message platform", async () => {
    const android: PushProvider = { send: vi.fn(async () => undefined) };
    const ios: PushProvider = { send: vi.fn(async () => undefined) };
    const composite = new CompositePushProvider({ android, ios });

    await composite.send({
      body: "Corpo",
      data: {},
      platform: "android",
      title: "Titulo",
      token: "android-token"
    });

    expect(android.send).toHaveBeenCalledOnce();
    expect(ios.send).not.toHaveBeenCalled();
  });

  it("throws when the platform has no configured provider", async () => {
    const composite = new CompositePushProvider({ android: { send: vi.fn() } });

    await expect(
      composite.send({
        body: "Corpo",
        data: {},
        platform: "ios",
        title: "Titulo",
        token: "ios-token"
      })
    ).rejects.toThrow(/No push provider configured/);
  });
});
