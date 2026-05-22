import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { AdminApiError, listAdminDisposals } from "@/core/lib/admin-api";

describe("admin-api", () => {
  const fetchMock = vi.fn();

  beforeEach(() => {
    vi.stubGlobal("fetch", fetchMock);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    fetchMock.mockReset();
  });

  it("falls back to generic error when payload is invalid", async () => {
    fetchMock.mockResolvedValue({
      ok: false,
      status: 500,
      json: async () => ({ message: "broken" })
    });

    await expect(listAdminDisposals("token", {})).rejects.toMatchObject({
      code: "INTERNAL_ERROR"
    });
  });

  it("builds query strings for list filters", async () => {
    fetchMock.mockResolvedValue({
      ok: true,
      json: async () => ({ data: [] })
    });

    await listAdminDisposals("token", {
      status: "awaiting_audit",
      priority: "high"
    });

    expect(fetchMock).toHaveBeenCalledWith(
      "http://localhost:4000/v1/admin/disposals?status=awaiting_audit&priority=high",
      expect.any(Object)
    );
  });

  it("parses API error payloads", async () => {
    fetchMock.mockResolvedValue({
      ok: false,
      status: 422,
      json: async () => ({
        error: {
          code: "BELOW_MIN_VOLUME",
          message: "Audited volume is below the active minimum."
        }
      })
    });

    await expect(listAdminDisposals("token", {})).rejects.toMatchObject({
      code: "BELOW_MIN_VOLUME"
    } satisfies Partial<AdminApiError>);
  });
});
