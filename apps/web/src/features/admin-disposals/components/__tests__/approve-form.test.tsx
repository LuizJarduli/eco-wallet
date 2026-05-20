import { cleanup, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

import { ApproveForm } from "@/features/admin-disposals/components/approve-form";

describe("ApproveForm", () => {
  afterEach(() => {
    cleanup();
  });

  it("submits estimated liters to handler", async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();

    render(<ApproveForm onSubmit={onSubmit} />);

    await user.clear(screen.getByRole("spinbutton"));
    await user.type(screen.getByRole("spinbutton"), "2.5");
    await user.click(screen.getByRole("button", { name: "Aprovar descarte" }));

    expect(onSubmit).toHaveBeenCalledWith(2.5);
  });

  it("does not submit invalid liter values", async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();

    render(<ApproveForm onSubmit={onSubmit} />);

    await user.clear(screen.getByRole("spinbutton"));
    await user.type(screen.getByRole("spinbutton"), "-1");
    await user.click(screen.getByRole("button", { name: "Aprovar descarte" }));

    expect(onSubmit).not.toHaveBeenCalled();
  });
});
