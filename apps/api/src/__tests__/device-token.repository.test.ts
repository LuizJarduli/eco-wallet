import { describe, expect, it } from "vitest";

import { SupabaseDeviceTokenRepository } from "../features/notifications/device-token.repository.js";

describe("SupabaseDeviceTokenRepository", () => {
  it("maps device token rows for a user", async () => {
    const client = {
      from: (table: string) => {
        expect(table).toBe("device_tokens");

        return {
          select: () => ({
            eq: async (_column: string, userId: string) => ({
              data: [
                {
                  id: "row-1",
                  platform: "android",
                  token: "token-a",
                  user_id: userId
                }
              ],
              error: null
            })
          })
        };
      }
    };

    const repository = new SupabaseDeviceTokenRepository(
      client as never
    );
    const tokens = await repository.listByUserId("member-1");

    expect(tokens).toEqual([
      {
        id: "row-1",
        platform: "android",
        token: "token-a",
        userId: "member-1"
      }
    ]);
  });
});
