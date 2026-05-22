import { cleanup, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

import { RejectForm } from "@/features/admin-disposals/components/reject-form";

describe("RejectForm", () => {
  afterEach(() => {
    cleanup();
  });

  it("disables submit until reasonCode is selected", () => {
    render(<RejectForm onSubmit={vi.fn()} />);

    expect(screen.getByRole("button", { name: "Rejeitar descarte" })).toBeDisabled();
  });

  it("enables submit after selecting a reason", async () => {
    const user = userEvent.setup();
    render(<RejectForm onSubmit={vi.fn()} />);

    await user.selectOptions(
      screen.getByLabelText("Motivo da rejeição"),
      "not_oil"
    );

    expect(screen.getByRole("button", { name: "Rejeitar descarte" })).toBeEnabled();
  });
});
