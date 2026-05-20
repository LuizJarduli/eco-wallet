import type { PushMessage, PushProvider } from "./push-provider.js";

export interface FcmPushProviderOptions {
  serverKey: string;
  fetchImpl?: typeof fetch;
}

export const createFcmPushProvider = (
  options: FcmPushProviderOptions
): PushProvider => {
  const fetchImpl = options.fetchImpl ?? fetch;

  return {
    async send(message: PushMessage): Promise<void> {
      const response = await fetchImpl("https://fcm.googleapis.com/fcm/send", {
        method: "POST",
        headers: {
          Authorization: `key=${options.serverKey}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          to: message.token,
          notification: {
            title: message.title,
            body: message.body
          },
          data: message.data
        })
      });

      if (!response.ok) {
        const body = await response.text();
        throw new Error(`FCM request failed (${response.status}): ${body}`);
      }
    }
  };
};
