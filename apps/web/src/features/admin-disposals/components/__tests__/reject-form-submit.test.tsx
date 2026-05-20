import { cleanup, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

import { RejectForm } from "@/features/admin-disposals/components/reject-form";

describe("RejectForm submit", () => {
  afterEach(() => {
    cleanup();
  });

  it("submits selected reason and optional note", async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();

    render(<RejectForm onSubmit={onSubmit} />);

    await user.selectOptions(
      screen.getByLabelText("Motivo da rejeição"),
      "unclear_photo"
    );
    await user.type(screen.getByRole("textbox"), "Foto escura");
    await user.click(screen.getByRole("button", { name: "Rejeitar descarte" }));

    expect(onSubmit).toHaveBeenCalledWith({
      reasonCode: "unclear_photo",
      note: "Foto escura"
    });
  });
});
