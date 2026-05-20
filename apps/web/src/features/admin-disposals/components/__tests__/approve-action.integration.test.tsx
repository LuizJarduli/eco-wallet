import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { useState } from "react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import { approveDisposal } from "@/core/lib/admin-api";
import { ApproveForm } from "@/features/admin-disposals/components/approve-form";

const ApproveFlow = () => {
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  return (
    <div>
      <ApproveForm
        onSubmit={async (estimatedLiters) => {
          await approveDisposal("admin-token", "sub-1", estimatedLiters);
          setSuccessMessage("Descarte aprovado e enviado para auditoria.");
        }}
      />
      {successMessage ? <p role="status">{successMessage}</p> : null}
    </div>
  );
};

describe("admin approve action integration", () => {
  const fetchMock = vi.fn();

  beforeEach(() => {
    vi.stubGlobal("fetch", fetchMock);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    fetchMock.mockReset();
  });

  it("approve button calls API mock and shows success", async () => {
    const user = userEvent.setup();

    fetchMock.mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ data: { pendingCoins: 20 } })
    });

    render(<ApproveFlow />);

    await user.click(screen.getByRole("button", { name: "Aprovar descarte" }));

    await waitFor(() => {
      expect(fetchMock).toHaveBeenCalledWith(
        "http://localhost:4000/v1/admin/disposals/sub-1/approve",
        expect.objectContaining({
          method: "POST",
          headers: expect.objectContaining({
            Authorization: "Bearer admin-token"
          }),
          body: JSON.stringify({ estimatedLiters: 1 })
        })
      );
    });

    expect(
      await screen.findByRole("status")
    ).toHaveTextContent("Descarte aprovado e enviado para auditoria.");
  });
});
