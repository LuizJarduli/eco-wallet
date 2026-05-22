import { createPrivateKey, sign } from "node:crypto";

import type { PushMessage, PushProvider } from "./push-provider.js";

export interface ApnsPushProviderOptions {
  keyId: string;
  teamId: string;
  bundleId: string;
  privateKey: string;
  useSandbox?: boolean;
  fetchImpl?: typeof fetch;
}

const createApnsJwt = (options: ApnsPushProviderOptions): string => {
  const header = Buffer.from(
    JSON.stringify({ alg: "ES256", kid: options.keyId })
  ).toString("base64url");
  const issuedAt = Math.floor(Date.now() / 1000);
  const payload = Buffer.from(
    JSON.stringify({ iss: options.teamId, iat: issuedAt })
  ).toString("base64url");
  const unsignedToken = `${header}.${payload}`;
  const signature = sign("sha256", Buffer.from(unsignedToken), {
    key: createPrivateKey(options.privateKey.replace(/\\n/g, "\n")),
    dsaEncoding: "ieee-p1363"
  }).toString("base64url");

  return `${unsignedToken}.${signature}`;
};

export const createApnsPushProvider = (
  options: ApnsPushProviderOptions
): PushProvider => {
  const fetchImpl = options.fetchImpl ?? fetch;
  const host = options.useSandbox
    ? "https://api.sandbox.push.apple.com"
    : "https://api.push.apple.com";

  return {
    async send(message: PushMessage): Promise<void> {
      const response = await fetchImpl(`${host}/3/device/${message.token}`, {
        method: "POST",
        headers: {
          authorization: `bearer ${createApnsJwt(options)}`,
          "apns-topic": options.bundleId,
          "apns-push-type": "alert",
          "content-type": "application/json"
        },
        body: JSON.stringify({
          aps: {
            alert: {
              title: message.title,
              body: message.body
            },
            sound: "default"
          },
          ...message.data
        })
      });

      if (!response.ok) {
        const body = await response.text();
        throw new Error(`APNs request failed (${response.status}): ${body}`);
      }
    }
  };
};
