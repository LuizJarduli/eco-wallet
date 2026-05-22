import { describe, expect, it, vi } from "vitest";

import { createFcmPushProvider } from "../features/notifications/fcm-push-provider.js";

describe("createFcmPushProvider", () => {
  it("posts notification payload to the legacy FCM endpoint", async () => {
    const fetchImpl = vi.fn(async () => new Response("{}", { status: 200 }));
    const provider = createFcmPushProvider({
      fetchImpl,
      serverKey: "server-key"
    });

    await provider.send({
      body: "Corpo",
      data: { deepLink: "ecowallet://disposal/submit" },
      platform: "android",
      title: "Titulo",
      token: "device-token"
    });

    expect(fetchImpl).toHaveBeenCalledWith(
      "https://fcm.googleapis.com/fcm/send",
      expect.objectContaining({
        headers: expect.objectContaining({
          Authorization: "key=server-key"
        }),
        method: "POST"
      })
    );
    expect(JSON.parse(String(fetchImpl.mock.calls[0]?.[1]?.body))).toMatchObject({
      data: { deepLink: "ecowallet://disposal/submit" },
      notification: { body: "Corpo", title: "Titulo" },
      to: "device-token"
    });
  });

  it("throws when FCM responds with an error status", async () => {
    const provider = createFcmPushProvider({
      fetchImpl: async () => new Response("bad", { status: 401 }),
      serverKey: "server-key"
    });

    await expect(
      provider.send({
        body: "Corpo",
        data: {},
        platform: "android",
        title: "Titulo",
        token: "device-token"
      })
    ).rejects.toThrow(/FCM request failed/);
  });
});
