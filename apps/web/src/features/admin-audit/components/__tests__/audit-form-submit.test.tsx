import { cleanup, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

import { AuditForm } from "@/features/admin-audit/components/audit-form";

describe("AuditForm submit", () => {
  afterEach(() => {
    cleanup();
  });

  it("calls onSubmit with audited liters", async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();

    render(<AuditForm onSubmit={onSubmit} />);

    await user.click(
      screen.getByRole("button", { name: "Confirmar coleta e liberar moedas" })
    );

    expect(onSubmit).toHaveBeenCalledWith(1);
  });

  it("does not submit invalid liter values", async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();

    render(<AuditForm onSubmit={onSubmit} />);

    await user.clear(screen.getByRole("spinbutton"));
    await user.type(screen.getByRole("spinbutton"), "0");
    await user.click(
      screen.getByRole("button", { name: "Confirmar coleta e liberar moedas" })
    );

    expect(onSubmit).not.toHaveBeenCalled();
  });
});
