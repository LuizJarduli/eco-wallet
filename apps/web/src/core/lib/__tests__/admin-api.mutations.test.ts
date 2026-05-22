import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import {
  approveDisposal,
  auditDisposal,
  rejectDisposal
} from "@/core/lib/admin-api";

describe("admin-api mutations", () => {
  const fetchMock = vi.fn();

  beforeEach(() => {
    vi.stubGlobal("fetch", fetchMock);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    fetchMock.mockReset();
  });

  it("posts approve payloads", async () => {
    fetchMock.mockResolvedValue({
      ok: true,
      json: async () => ({ data: { pendingCoins: 10 } })
    });

    await approveDisposal("token", "sub-1", 2);

    expect(fetchMock).toHaveBeenCalledWith(
      "http://localhost:4000/v1/admin/disposals/sub-1/approve",
      expect.objectContaining({
        method: "POST",
        body: JSON.stringify({ estimatedLiters: 2 })
      })
    );
  });

  it("posts reject payloads and handles 204", async () => {
    fetchMock.mockResolvedValue({ ok: true, status: 204 });

    await rejectDisposal("token", "sub-1", "not_oil", "note");

    expect(fetchMock).toHaveBeenCalledWith(
      "http://localhost:4000/v1/admin/disposals/sub-1/reject",
      expect.objectContaining({
        method: "POST",
        body: JSON.stringify({ reasonCode: "not_oil", note: "note" })
      })
    );
  });

  it("posts audit payloads", async () => {
    fetchMock.mockResolvedValue({
      ok: true,
      json: async () => ({ data: { coinsReleased: 8 } })
    });

    await auditDisposal("token", "sub-1", 1.5);

    expect(fetchMock).toHaveBeenCalledWith(
      "http://localhost:4000/v1/admin/disposals/sub-1/audit",
      expect.objectContaining({
        method: "POST",
        body: JSON.stringify({ auditedLiters: 1.5 })
      })
    );
  });
});
